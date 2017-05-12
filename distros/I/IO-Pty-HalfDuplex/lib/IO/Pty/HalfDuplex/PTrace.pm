#!/usr/bin/env perl
# vim: fdm=marker sw=4 et
# Documentation head {{{

=head1 NAME

IO::Pty::HalfDuplex::PTrace - identify reads using syscall tracing

=head1 SYNOPSIS

    IO::Pty::HalfDuplex->new(backend => 'PTrace')

=head1 CAVEATS

C<IO::Pty::HalfDuplex::PTrace> is extremely sensitive to OS and architecture;
currently it only works on FreeBSD i386 and amd64.

C<IO::Pty::HalfDuplex::PTrace> does not know about ABI emulations used by the
target, and will fail on anything compiled for a different ABI than Perl.

=head1 BUGS

See L<IO::Pty::HalfDuplex>.

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Stefan O'Rear.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# }}}
# header {{{
package IO::Pty::HalfDuplex::PTrace;

use strict;
use warnings;
use POSIX '_exit', ':sys_wait_h', 'tcsetpgrp';

use base 'IO::Pty::HalfDuplex::Ptyish';

BEGIN {
    die "XS code for IO::Pty::HalfDuplex::PTrace not built."
        unless __PACKAGE__->can('_fork_traced');
}

# }}}
# _report_death {{{
sub _report_death {
    my $self = shift;

    syswrite $self->{info_pipe}, "d" .
        chr(WIFSIGNALED($?) ? WTERMSIG($?) : 0) .
        chr(WIFEXITED($?) ? WEXITSTATUS($?) : 0);
        
    # We got here by a fork, so we certainly have stale buffers
    _exit 0;
}
# }}}
# control loop and startup {{{
# Wait for, and process, commands
sub _shell_loop {
    my $self = shift;

    while(1) {
        my $buf = '';
        sysread($self->{ctl_pipe}, $buf, 1) > 0 or die "read(ctl): $!";

        while (1) {
            my $rin = '';
            vec($rin, 0, 1) = 1;
            tcsetpgrp(0, $self->{pid});
            last unless select($rin, undef, undef, 0);
            tcsetpgrp(0, $self->{slave_pid});
            
            _continue_to_next_read($self->{slave_pid})
                or $self->_report_death;
        }
        tcsetpgrp(0, $self->{slave_pid});

        syswrite($self->{info_pipe}, "r");
    }
}

# This routine is responsible for creating the proper environment for the
# slave to run in.
sub _shell_spawn {
    my $self = shift;

    $self->{slave_pid} = _fork_traced;

    if ($self->{slave_pid} == -1) {
        # XXX yucky interface, what can be sensibly done
        # child died before first trap, probably exec failure
        $self->_report_death;
    }

    unless ($self->{slave_pid}) {
        exec(@{$self->{command}});
        die "exec: $!";
    }

    tcsetpgrp(0, $self->{slave_pid});
    syswrite($self->{info_pipe}, pack('N', $self->{slave_pid}));

    _continue_to_next_read $self->{slave_pid}
        or $self->_report_death;
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
