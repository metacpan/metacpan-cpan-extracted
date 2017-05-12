#!/usr/bin/env perl
# vim: fdm=marker sw=4 et
package IO::Pty::HalfDuplex;
# POD header {{{

=head1 NAME

IO::Pty::HalfDuplex - Treat interactive programs like subroutines

=head1 SYNOPSIS

    use IO::Pty::HalfDuplex;

    my $pty = IO::Pty::HalfDuplex->new;

    $pty->spawn("nethack");

    $pty->read;
    # => "\nNetHack, copyright...for you? [ynq] "

    $pty->write("nvd");
    $pty->read;

    # => "... Velkommen sorear, you are a lawful dwarven Valkyrie.--More--"

=head1 DESCRIPTION

C<IO::Pty::HalfDuplex> is designed to perform impedence matching between
driving programs which expect commands and responses, and driven programs
which use a terminal in full-duplex mode.  In this vein it is somewhat like
I<expect>, but less general and more robust (but see CAVEATS below).

This module is used in object-oriented style.  IO::Pty::HalfDuplex objects
are connected to exactly one system pseudoterminal, which is allocated on
creation; input and output are done using methods.  The interface is
deliberately kept similar to Jesse Luehrs' L<IO::Pty::Easy> module; notable
incompatibilities from the latter are:

=over

=item *

The spawn() method reports failure to exec inline, on output followed
by an exit.  I see no reason why exec failures should be different from post-exec failures such as "dynamic library not found", and it considerably simplifes the code.

=item *

write() does not immediately write anything, but merely queues data to be released all at once by read().  It does not have a timeout parameter.

=item *

read() should generally not be passed a timeout, as it finds the end of output automatically.

=item *

The two-argument form of kill() interprets its second argument in the opposite sense.

=back

=head1 METHODS

=cut

# }}}
# Imports {{{
use strict;
use warnings;

use 5.006_002;

our $VERSION = '0.02';
# }}}
# new {{{
# Most of this is handled by IO::Pty, thankfully

=head2 new(%args)

Allocates and returns a IO::Pty::HalfDuplex object.  The named argument
'backend' selects a backend, other arguments, if any, are in the backend's
documentation.  If the backend is not specified, one will be defaulted based
on platform, or using C<$ENV{IO_PTY_HALFDUPLEX_BACKEND}> if it exists.
Currently supported backends:

=over 2

=item JobControl

Using POSIX job control.  Theoretically portable to all UNIXes, in practice
bugs require workarounds on many systems.  Most BSDs (but not recent Darwin)
have a kernel issue which makes this unusably slow (several seconds per read).
The default on UNIX.

=item SysctlPoll

Using BSD-style C<sysctl> process access.  The default on FreeBSD, OpenBSD,
and NetBSD.

=item PTrace

Using the highly nonportable I<ptrace> call.  Could be ported to most Unixes,
but at present only works on i386 and amd64 FreeBSD; other popular platforms
support simpler methods.

=back

=cut

my $_default_backend = $ENV{IO_PTY_HALFDUPLEX_BACKEND};
undef $_default_backend unless ($_default_backend || '') =~ /^[A-Za-z0-9_]+$/;

sub _probe_backends {
    # Only one backend can possibly work for these
    return 'DOS' if $^O eq 'dos';
    return 'WinDebug' if $^O eq 'MSWin32';

    # anything else is either unsupported or a unix-a-like
    # JobControl is the most portable, but is very inefficient
    # on BSDkin other than Darwin

    return 'JobControl' unless $^O =~ /bsd/i;

    return 'SysctlPoll' if IO::Pty::HalfDuplex::SysctlPoll->can('_is_waiting');
    return 'PTrace'     if IO::Pty::HalfDuplex::PTrace->can('_fork_traced');
    return 'JobControl';
}

sub new {
    my $class = shift;
    my %args = @_;

    if (! defined $args{backend}) {
        $args{backend} = ($_default_backend ||= _probe_backends());
    }

    eval "require IO::Pty::HalfDuplex::$args{backend}";
    die $@ if $@;

    ("IO::Pty::HalfDuplex::" . $args{backend})->new(@_);
}

# If any XS-based backends were build, we need to load them now.
# If not, or if your system doesn't support XS, you can still use
# the pure-Perl backends (JobControl and maybe Stupid).

eval {
    local $SIG{__DIE__};

    require XSLoader;
    &XSLoader::load("IO::Pty::HalfDuplex", $VERSION);
};

1;

__END__ 
# }}}
# Method documentation {{{

=head2 spawn(I<LIST>)

Starts a subprocess under the control of IO::Pty::HalfDuplex.  I<LIST> may be
a single string or list of strings as per Perl exec.

=head2 recv([I<TIMEOUT>])

Reads all output that the subprocess will send.  If I<TIMEOUT> is specified and
the process has not finished writing, undef is returned and the existing output
is retained in the read buffer for use by subsequent recv calls.

I<TIMEOUT> is in (possibly fractional) seconds.

=head2 write(I<TEXT>)

Appends I<TEXT> to the write buffer to be sent on the next recv.

=head2 is_active()

Returns true if the slave process currently exists.

=head2 kill()

Sends a signal to the process currently running on the pty (if any). Optionally blocks until the process dies.

C<kill()> takes an even number of arguments.  They are interpreted as pairs of signals and a length of time to wait after each one, or 0 to not wait at all.  Signals may be in any format that the Perl C<kill()> command recognizes.  Any output generated while waiting is discarded.

Returns 1 immediately if the process exited during a wait, 0 if it was successfully signalled but did not exit, and undef if the signalling failed.

C<kill()> (with no arguments) is equivalent to C<< kill(TERM => 3, KILL => 3) >>.

C<kill()> may not be fully implemented on non-UNIX backends.

=head2 close()

Kills any subprocesses and closes the pty. No other operations are valid after this call.

=cut

# }}}
# Documentation tail {{{

=head1 CAVEATS

In general, C<IO::Pty::HalfDuplex> relies on processes accessing the terminal
in a single-threaded way.  If you manage to write while blocking on a read,
or never use blocking reads, C<IO::Pty::HalfDuplex> will break.  In particular,
programs like C<qemu> and C<telnet> cannot be expected to ever work with this.

Each backend has its own long list of caveats; see the relevant documentation.

=head1 SEE ALSO

L<IO::Pty::HalfDuplex::JobControl> and related modules.  L<IO::Pty::Easy>.
L<TAEB>, the first and motivating user of this module.  L<Expect>, a
superficially similar module with an entirely different implementation.

=head1 AUTHOR

Stefan O'Rear, C<< <stefanor@cox.net> >>

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-io-pty-halfduplex at rt.cpan.org>, or browse
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Pty-HalfDuplex>.

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Stefan O'Rear.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# }}}
