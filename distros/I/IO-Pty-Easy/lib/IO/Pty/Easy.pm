package IO::Pty::Easy;
our $AUTHORITY = 'cpan:DOY';
$IO::Pty::Easy::VERSION = '0.10';
use warnings;
use strict;
# ABSTRACT: Easy interface to IO::Pty

use Carp;
use POSIX ();
use Scalar::Util qw(weaken);

use base 'IO::Pty';



sub new {
    my $class = shift;
    my %args = @_;

    my $handle_pty_size = 1;
    $handle_pty_size = delete $args{handle_pty_size}
        if exists $args{handle_pty_size};
    $handle_pty_size = 0 unless POSIX::isatty(*STDIN);
    my $def_max_read_chars = 8192;
    $def_max_read_chars = delete $args{def_max_read_chars}
        if exists $args{def_max_read_chars};
    my $raw = 1;
    $raw = delete $args{raw}
        if exists $args{raw};

    my $self = $class->SUPER::new(%args);
    bless $self, $class;
    $self->handle_pty_size($handle_pty_size);
    $self->def_max_read_chars($def_max_read_chars);
    ${*{$self}}{io_pty_easy_raw} = $raw;
    ${*{$self}}{io_pty_easy_final_output} = '';
    ${*{$self}}{io_pty_easy_did_handle_pty_size} = 0;

    return $self;
}


sub spawn {
    my $self = shift;
    my $slave = $self->slave;

    croak "Attempt to spawn a subprocess when one is already running"
        if $self->is_active;

    # set up a pipe to use for keeping track of the child process during exec
    my ($readp, $writep);
    unless (pipe($readp, $writep)) {
        croak "Failed to create a pipe";
    }
    $writep->autoflush(1);

    # fork a child process
    # if the exec fails, signal the parent by sending the errno across the pipe
    # if the exec succeeds, perl will close the pipe, and the sysread will
    # return due to EOF
    ${*{$self}}{io_pty_easy_pid} = fork;
    unless ($self->pid) {
        close $readp;
        $self->make_slave_controlling_terminal;
        close $self;
        $slave->clone_winsize_from(\*STDIN) if $self->handle_pty_size;
        $slave->set_raw if ${*{$self}}{io_pty_easy_raw};
        # reopen the standard file descriptors in the child to point to the
        # pty rather than wherever they have been pointing during the script's
        # execution
        open(STDIN,  '<&', $slave->fileno)
            or carp "Couldn't reopen STDIN for reading";
        open(STDOUT, '>&', $slave->fileno)
            or carp "Couldn't reopen STDOUT for writing";
        open(STDERR, '>&', $slave->fileno)
            or carp "Couldn't reopen STDERR for writing";
        close $slave;
        { exec(@_) };
        print $writep $! + 0;
        carp "Cannot exec(@_): $!";
        exit 1;
    }

    close $writep;
    $self->close_slave;
    # this sysread will block until either we get an EOF from the other end of
    # the pipe being closed due to the exec, or until the child process sends
    # us the errno of the exec call after it fails
    my $errno;
    my $read_bytes = sysread($readp, $errno, 256);
    unless (defined $read_bytes) {
        # XXX: should alarm here and follow up with SIGKILL if the process
        # refuses to die
        kill TERM => $self->pid;
        close $readp;
        $self->_wait_for_inactive;
        croak "Cannot sync with child: $!";
    }
    close $readp;
    if ($read_bytes > 0) {
        $errno = $errno + 0;
        $self->_wait_for_inactive;
        croak "Cannot exec(@_): $errno";
    }

    if ($self->handle_pty_size) {
        my $weakself = weaken($self);
        $SIG{WINCH} = sub {
            return unless $weakself;
            $weakself->slave->clone_winsize_from(\*STDIN);
            kill WINCH => $weakself->pid if $weakself->is_active;
        };
        ${*{$self}}{io_pty_easy_did_handle_pty_size} = 1;
    }
}


sub read {
    my $self = shift;
    my ($timeout, $max_chars) = @_;
    $max_chars ||= $self->def_max_read_chars;

    my $rin = '';
    vec($rin, fileno($self), 1) = 1;
    my $nfound = select($rin, undef, undef, $timeout);
    my $buf;
    if ($nfound > 0) {
        my $nchars = sysread($self, $buf, $max_chars);
        $buf = '' if defined($nchars) && $nchars == 0;
    }
    if (length(${*{$self}}{io_pty_easy_final_output}) > 0) {
        no warnings 'uninitialized';
        $buf = ${*{$self}}{io_pty_easy_final_output} . $buf;
        ${*{$self}}{io_pty_easy_final_output} = '';
    }
    return $buf;
}


sub write {
    my $self = shift;
    my ($text, $timeout) = @_;

    my $win = '';
    vec($win, fileno($self), 1) = 1;
    my $nfound = select(undef, $win, undef, $timeout);
    my $nchars;
    if ($nfound > 0) {
        $nchars = syswrite($self, $text);
    }
    return $nchars;
}


sub is_active {
    my $self = shift;

    return 0 unless defined $self->pid;

    if (defined(my $fd = fileno($self))) {
        # XXX FreeBSD 7.0 will not allow a session leader to exit until the
        # kernel tty output buffer is empty.  Make it so.
        my $rin = '';
        vec($rin, $fd, 1) = 1;
        my $nfound = select($rin, undef, undef, 0);
        if ($nfound > 0) {
            sysread($self, ${*{$self}}{io_pty_easy_final_output},
                    $self->def_max_read_chars,
                    length ${*{$self}}{io_pty_easy_final_output});
        }
    }

    my $active = kill 0 => $self->pid;
    if ($active) {
        my $pid = waitpid($self->pid, POSIX::WNOHANG());
        $active = 0 if $pid == $self->pid;
    }
    if (!$active) {
        $SIG{WINCH} = 'DEFAULT'
            if ${*{$self}}{io_pty_easy_did_handle_pty_size};
        ${*{$self}}{io_pty_easy_did_handle_pty_size} = 0;
        delete ${*{$self}}{io_pty_easy_pid};
    }
    return $active;
}


sub kill {
    my $self = shift;
    my ($sig, $non_blocking) = @_;
    $sig = "TERM" unless defined $sig;

    my $kills;
    $kills = kill $sig => $self->pid if $self->is_active;
    $self->_wait_for_inactive unless $non_blocking;

    return $kills;
}


sub close {
    my $self = shift;

    close $self;
    $self->kill;
}


sub handle_pty_size {
    my $self = shift;
    ${*{$self}}{io_pty_easy_handle_pty_size} = $_[0] if @_;
    ${*{$self}}{io_pty_easy_handle_pty_size};
}


sub def_max_read_chars {
    my $self = shift;
    ${*{$self}}{io_pty_easy_def_max_read_chars} = $_[0] if @_;
    ${*{$self}}{io_pty_easy_def_max_read_chars};
}


sub pid {
    my $self = shift;
    ${*{$self}}{io_pty_easy_pid};
}

sub _wait_for_inactive {
    my $self = shift;

    select(undef, undef, undef, 0.01) while $self->is_active;
}

sub DESTROY {
    my $self = shift;
    local $@;
    local $?;
    $self->close;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Pty::Easy - Easy interface to IO::Pty

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use IO::Pty::Easy;

    my $pty = IO::Pty::Easy->new;
    $pty->spawn("nethack");

    while ($pty->is_active) {
        my $input = # read a key here...
        $input = 'Elbereth' if $input eq "\ce";
        my $chars = $pty->write($input, 0);
        last if defined($chars) && $chars == 0;
        my $output = $pty->read(0);
        last if defined($output) && $output eq '';
        $output =~ s/Elbereth/\e[35mElbereth\e[m/;
        print $output;
    }

    $pty->close;

=head1 DESCRIPTION

C<IO::Pty::Easy> provides an interface to L<IO::Pty> which hides most of the
ugly details of handling ptys, wrapping them instead in simple spawn/read/write
commands.

C<IO::Pty::Easy> uses L<IO::Pty> internally, so it inherits all of the
portability restrictions from that module.

=head1 METHODS

=head2 new(%params)

The C<new> constructor initializes the pty and returns a new C<IO::Pty::Easy>
object. The constructor recognizes these parameters:

=over 4

=item handle_pty_size

A boolean option which determines whether or not changes in the size of the
user's terminal should be propageted to the pty object. Defaults to true.

=item def_max_read_chars

The maximum number of characters returned by a C<read()> call. This can be
overridden in the C<read()> argument list. Defaults to 8192.

=item raw

A boolean option which determines whether or not to call L<IO::Pty/set_raw()>
after C<spawn()>. Defaults to true.

=back

=head2 spawn(@argv)

Fork a new subprocess, with stdin/stdout/stderr tied to the pty.

The argument list is passed directly to C<system()>.

Dies on failure.

=head2 read($timeout, $length)

Read data from the process running on the pty.

C<read()> takes two optional arguments: the first is the number of seconds
(possibly fractional) to block for data (defaults to blocking forever, 0 means
completely non-blocking), and the second is the maximum number of bytes to read
(defaults to the value of C<def_max_read_chars>, usually 8192). The requirement
for a maximum returned string length is a limitation imposed by the use of
C<sysread()>, which we use internally.

Returns C<undef> on timeout, the empty string on EOF, or a string of at least
one character on success (this is consistent with C<sysread()> and
L<Term::ReadKey>).

=head2 write($buf, $timeout)

Writes a string to the pty.

The first argument is the string to write, which is followed by one optional
argument, the number of seconds (possibly fractional) to block for, taking the
same values as C<read()>.

Returns undef on timeout, 0 on failure to write, or the number of bytes
actually written on success (this may be less than the number of bytes
requested; this should be checked for).

=head2 is_active

Returns whether or not a subprocess is currently running on the pty.

=head2 kill($sig, $non_blocking)

Sends a signal to the process currently running on the pty (if any). Optionally
blocks until the process dies.

C<kill()> takes two optional arguments. The first is the signal to send, in any
format that the perl C<kill()> command recognizes (defaulting to "TERM"). The
second is a boolean argument, where false means to block until the process
dies, and true means to just send the signal and return.

Returns 1 if a process was actually signaled, and 0 otherwise.

=head2 close

Kills any subprocesses and closes the pty. No other operations are valid after
this call.

=head2 handle_pty_size

Read/write accessor for the C<handle_pty_size> option documented in
L<the constructor options|/new(%params)>.

=head2 def_max_read_chars

Read/write accessor for the C<def_max_read_chars> option documented in
L<the constructor options|/new(%params)>.

=head2 pid

Returns the pid of the process currently running in the pty, or undef if no
process is running.

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-io-pty-easy at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Pty-Easy>.

=head1 SEE ALSO

L<IO::Pty>

(This module is based heavily on the F<try> script bundled with L<IO::Pty>.)

L<Expect>

L<IO::Pty::HalfDuplex>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc IO::Pty::Easy

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Pty-Easy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-Pty-Easy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Pty-Easy>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-Pty-Easy>

=back

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
