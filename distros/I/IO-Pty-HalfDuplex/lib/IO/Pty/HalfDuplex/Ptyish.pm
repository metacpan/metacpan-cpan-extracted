#!/usr/bin/env perl
# vim: fdm=marker sw=4 et
package IO::Pty::HalfDuplex::Ptyish;
# Notes on design {{{
# IO::Pty::HalfDuplex operates by mimicing a job-control shell.  A process
# is done sending data when it calls read, which we notice because it
# results in Stopped (tty input).  So far, fairly simple.  Complications
# arise because of races, and also because shells are required to run in
# the managed tty, and be the parent of the process; this forces us to use
# a stub process and simple IPC.
# }}}
# POD header {{{

=head1 NAME

IO::Pty::HalfDuplex::Ptyish - Base class for pty-using HalfDuplex backends

=head1 SYNOPSIS

    package IO::Pty::HalfDuplex::PTrace;

    use base 'IO::Pty::HalfDuplex::Ptyish';

    sub shell {
        my %args = @_;

        #start subprocess
        syswrite $args->{info_pipe}, pack("N", $pid);

        while(1) {
            # wait for subprocess to block
            if (subprocess died) {
                syswrite $args->{info_pipe}, "d" . pack("CC", $sig, $code);
                POSIX::_exit();
            }

            syswrite $args->{info_pipe}, "r";
            sysread $args->{ctl_pipe}, $_, 1;

            # continue subprocess
        }
    }

    1;

=head1 DESCRIPTION

C<IO::Pty::HalfDuplex::Ptyish> is the base class for pty-using HalfDuplex
backends.  It implements the HalfDuplex methods by opening a pty and starting
a slave process to control the child; this slave communicates with the main
process using a pair of pipes.  Subclasses must implement the C<shell()>
method, with the following specification:

=head2 $pty->shell(info_pipe => $status_fh, ctl_pipe => $control_fh,
    command => \@argv)

C<shell> forks and starts the child process as if by C<exec(@argv)>.  It then
writes the PID of the child in C<pack "N"> format to $status_fh, and enters
an infinite loop in the parent.  Each time the child stops waiting for input,
the character "r" is written to $status_fd; the client process will request
a restart by putting more data into the pty buffer and writing "s" to
$control_fh.  When the child exits, write a "d" to $status_fd, followed 
by the child's exit signal or 0 and exit code or 0, each in C<pack "C"> format.
The shell then calls _exit.

=cut

# }}}
# Imports {{{
use strict;
use warnings;
use base 'IO::Pty::HalfDuplex';
use POSIX qw(:unistd_h :sys_wait_h :signal_h EIO);
use Carp;
use IO::Pty;
use Time::HiRes qw(time);
our $_infinity = 1e1000;
# }}}
# new {{{
# Most of this is handled by IO::Pty, thankfully

sub new {
    my $class = shift;
    my $self = {
        # options
        buffer_size => 8192,
        @_,

        # state
        pty => undef,
        active => 0,
        exit_code => undef,
    };

    bless $self, $class;

    $self->{pty} = new IO::Pty;

    return $self;
}
# }}}
sub spawn {
    my $self = shift;
    my $slave = $self->{pty}->slave;

    croak "Attempt to spawn a subprocess when one is already running"
        if $self->is_active;

    pipe (my $p1r, my $p1w) || croak "Failed to create a pipe";
    pipe (my $p2r, my $p2w) || croak "Failed to create a pipe";

    $self->{info_pipe} = $p1r;
    $self->{ctl_pipe} = $p2w;

    defined ($self->{shell_pid} = fork) || croak "fork: $!";

    unless ($self->{shell_pid}) {
        close $p1r;
        close $p2w;
        $self->{pty}->make_slave_controlling_terminal;
        close $self->{pty};
        $slave->set_raw;
        # reopen the standard file descriptors in the child to point to the
        # pty rather than wherever they have been pointing during the script's
        # execution
        open(STDIN,  "<&" . $slave->fileno)
            or carp "Couldn't reopen STDIN for reading";
        open(STDOUT, ">&" . $slave->fileno)
            or carp "Couldn't reopen STDOUT for writing";
        open(STDERR, ">&" . $slave->fileno)
            or carp "Couldn't reopen STDERR for writing";
        close $slave;

        $self->_shell(info_pipe => $p1w, ctl_pipe => $p2r,
            command => [@_]);
    }

    close $p1w;
    close $p2r;
    $self->{pty}->close_slave;
    $self->{pty}->set_raw;

    my ($rcpid);
    my $syncd = sysread($self->{info_pipe}, $rcpid, 4);

    unless ($syncd == 4) {
        croak "Cannot sync with child: $!";
    }
    $self->{slave_pgid} = unpack "N", $rcpid;

    $self->{read_buffer} = $self->{write_buffer} = '';
    $self->{sent_sync} = 0; $self->{active} = 1;
    $self->{timeout} = $self->{exit_code} = $self->{exit_sig} = undef;
}
# }}}
# I/O on shell pipes {{{
# Process a wait result from the shell
sub _handle_info_read {
    my $self = shift;
    my $ibuf;

    my $ret = sysread $self->{info_pipe}, $ibuf, 1;

    if ($ret == 0) {
        # Shell has exited
        $self->{sent_sync} = 0;
        $self->{active} = 0;
        # FreeBSD 7 (and presumably other BSDkin) requires the pty output
        # buffer to be drained before any session leader can exit.
        $self->_handle_pty_drain;
        # Reap the shell
        waitpid($self->{shell_pid}, 0);

        if (!defined $self->{exit_code}) {
            # Get the shell crash code
            $self->{exit_sig}  = WIFSIGNALED($?) ? WTERMSIG($?) : 0;
            $self->{exit_code} = WIFEXITED($?) ? WEXITSTATUS($?) : 0;
        }
    } elsif ($ibuf eq 'd') {
        sysread $self->{info_pipe}, $ibuf, 2;

        @{$self}{"exit_sig","exit_code"} = unpack "CC", $ibuf;
    } elsif ($ibuf eq 'r') {
        $self->{sent_sync} = 0;
    }
}

sub _handle_pty_write {
    my ($self, $ref) = @_;

    my $ct = syswrite $self->{pty}, $self->{write_buffer}
        or die "write(pty): $!";

    $self->{write_buffer} = substr($self->{write_buffer}, $ct);
}

sub _handle_pty_read {
    my ($self) = @_;

    return if defined (sysread $self->{pty}, $self->{read_buffer},
        $self->{buffer_size}, length $self->{read_buffer});

    # Under Linux, any pty read can randomly return EIO if the
    # session leader exits racily.
    return if $! == &POSIX::EIO and $^O eq "linux";

    die "read(pty): $!";
}

sub _handle_pty_drain {
    my ($self) = @_;

    while (1) {
        my $got = sysread $self->{pty}, $self->{read_buffer},
            $self->{buffer_size}, length $self->{read_buffer};

        return if defined $got && $got == 0;
        next if defined $got;

        # Under Linux, any pty read can randomly return EIO if the
        # session leader exits racily.
        return if $! == &POSIX::EIO and $^O eq "linux";

        die "drain(pty): $!";
    }
}
# }}}
# Read internals {{{
# A little something to make all these select loops nicer
sub _select_loop {
    my ($self, $block, $pred) = splice @_, 0, 3;

    while ($pred->()) {
        my %mask = ('r' => '', 'w' => '', 'x' => '');

        my $tmo = !$block ? 0 :
            defined $self->{timeout} ? $self->{timeout} - time : undef;

        for (@_) {
            vec($mask{$_->[1]}, fileno($_->[0]), 1) = 1
                if @$_ < 4 || $_->[3];
        }

        return 1 if ($tmo||0)< 0 || !select($mask{r}, $mask{w}, $mask{x}, $tmo);

        for (@_) {
            $_->[2]() if vec($mask{$_->[1]}, fileno($_->[0]), 1);
        }
    }
}

# We want to return when the slave has processed all input.  We have to
# break it up into pty-buffer-sized chunks, though.
sub _process_wait {
    my ($self) = shift;

    $self->_select_loop(1 => sub{ $self->{sent_sync} },
        [ $self->{info_pipe}, r => sub { $self->_handle_info_read() } ],
        [ $self->{pty}, r       => sub { $self->_handle_pty_read() } ]);
}

# Send as much data as possible
sub _process_send {
    my ($self) = @_;

    $self->_select_loop(0 => sub{ $self->{write_buffer} ne '' },
        [ $self->{info_pipe}, r => sub { $self->_handle_info_read() } ],
        [ $self->{pty}, r => sub { $self->_handle_pty_read() } ],
        [ $self->{pty}, w => sub { $self->_handle_pty_write() } ]);
}

sub _send_sync {
    my $self = shift;
    return if $self->{sent_sync};
    syswrite $self->{ctl_pipe}, "s";
    $self->{sent_sync} = 1;
}
# }}}
# I/O operations {{{

sub recv {
    my ($self, $timeout) = @_;

    if (! $self->is_active) {
        carp "Reading from dead slave";
        return;
    }

    $self->{timeout} = defined $timeout ? $timeout + time : undef;

    do  {
        $self->_process_send();
        $self->_send_sync();
        return undef if $self->_process_wait();
    } while ($self->{write_buffer} ne '' && $self->{active});

    my $t = $self->{read_buffer};
    $self->{read_buffer} = '';
    $t;
}

sub write {
    my ($self, $text) = @_;

    if (! $self->is_active) {
        carp "Writing to dead slave";
        return;
    }

    $self->{write_buffer} .= $text;
}

sub is_active {
    my $self = shift;

    return $self->{active};
}

sub _wait_for_inactive {
    my $self = shift;
    my $targ = shift;

    $targ = defined $targ ? $targ + time : undef;

    do {
        $self->recv(defined $targ ? $targ - time : undef);
    } while ($targ > time && $self->is_active);

    !$self->is_active;
}
# }}}
# kill() {{{
sub kill {
    my $self = shift;

    if (@_ < 2) { @_ = (TERM => 3, KILL => 3); }

    return 1 if !$self->is_active;

    while (@_ >= 2) {
        my ($sig, $tme) = splice @_, 0, 2;
        
        kill $sig => -$self->{slave_pgid}
            or return undef;

        $tme = defined $tme ? $tme : $_infinity;

        if ($tme && $self->_wait_for_inactive($tme)) {
            return 1;
        }
    }

    return 0;
}
# }}}
# close() {{{
sub close {
    my $self = shift;

    $self->kill;
    close $self->{pty};
    $self->{pty} = undef;
}
# }}}
# documentation tail {{{

sub _shell {
    my $class = ref(shift);

    die ($class eq 'IO::Pty::HalfDuplex::Ptyish')
        ? "You must subclass Ptyish, not use it directly"
        : "You need to override shell() in Ptyish subclasses";
}

1;

__END__

=head1 AUTHOR

Stefan O'Rear, C<< <stefanor@cox.net> >>

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-io-halfduplex at rt.cpan.org>, or browse
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-HalfDuplex>.

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Stefan O'Rear.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# }}}
