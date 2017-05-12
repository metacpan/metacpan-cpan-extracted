#!/usr/bin/env perl
# vim: fdm=marker sw=4 et
# Documentation head {{{

=head1 NAME

IO::Pty::HalfDuplex::SysctlPoll - wait for blocking reads using sysctl

=head1 SYNOPSIS

    IO::Pty::HalfDuplex->new(backend => 'SysctlPoll')

=head1 CAVEATS

C<IO::Pty::HalfDuplex::SyctlPoll> needs to poll, and will waste a certain
amount of CPU time while the child runs.

Otherwise it is probably the most robust backend.

=head1 BUGS

See L<IO::Pty::HalfDuplex>.

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Stefan O'Rear.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# }}}
# header {{{
package IO::Pty::HalfDuplex::SysctlPoll;

use strict;
use warnings;
use POSIX '_exit', ':sys_wait_h', 'tcsetpgrp', 'setpgid';

use base 'IO::Pty::HalfDuplex::Ptyish';

BEGIN {
    die "XS code for IO::Pty::HalfDuplex::SysctlPoll not built."
        unless __PACKAGE__->can('_is_waiting');
}

# }}}
# control loop and startup {{{
# Wait for, and process, commands
sub _shell_loop {
    my $self = shift;

    while(1) {
        my $buf = '';
        sysread($self->{ctl_pipe}, $buf, 1) > 0 or die "read(ctl): $!";

        my $lag = 0.05;

        while (!_is_waiting($self->{slave_pid})) {
            if (waitpid($self->{slave_pid}, &POSIX::WNOHANG) > 0) {
                syswrite $self->{info_pipe}, "d" .
                    chr(WIFSIGNALED($?) ? WTERMSIG($?) : 0) .
                    chr(WIFEXITED($?) ? WEXITSTATUS($?) : 0);
                
                _exit 0;
            }

            select undef, undef, undef, ($lag *= 1.1);
        }

        syswrite($self->{info_pipe}, "r");
    }
}

# This routine is responsible for creating the proper environment for the
# slave to run in.
sub _shell_spawn {
    my $self = shift;

    $self->{slave_pid} = fork;

    die "fork: $!" unless defined $self->{slave_pid};

    unless ($self->{slave_pid}) {
        my $pid = $$;
        $SIG{TTOU} = 'IGNORE';
        setpgid($pid, $pid);
        tcsetpgrp(0, $pid);
        $SIG{TTOU} = 'DEFAULT';

        exec(@{$self->{command}});
        die "exec: $!";
    }

    syswrite($self->{info_pipe}, pack('N', $self->{slave_pid}));
}

sub _shell {
    my $self = shift;
    %$self = (
        %$self,
        pid => $$,
        @_
    );

    $self->_shell_spawn();
    $self->_shell_loop();
}
1;
# }}}
