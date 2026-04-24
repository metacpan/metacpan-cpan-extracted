# Documentation at the __END__
# -*-cperl-*-

package IO::Tty;

use 5.008008;

use strict;
use warnings;
use IO::Handle;
use IO::File;
use IO::Tty::Constant;
use Carp;

require POSIX;

our @ISA        = qw(IO::Handle);
our $VERSION = '1.29';
our ( $CONFIG, $DEBUG );

eval { local $^W = 0; local $SIG{__DIE__}; require IO::Stty };
push @ISA, "IO::Stty" if ( not $@ );    # if IO::Stty is installed

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub import {
    IO::Tty::Constant->export_to_level( 1, @_ );
}

sub open {
    my ( $tty, $dev, $mode ) = @_;

    IO::File::open( $tty, $dev, $mode )
      or return undef;

    $tty->autoflush;

    1;
}

sub clone_winsize_from {
    my ( $self, $fh ) = @_;
    croak "Given filehandle is not a tty in clone_winsize_from, called"
      if not POSIX::isatty($fh);
    return 1 if not POSIX::isatty($self);    # ignored for master ptys
    my $winsize = IO::Tty::pack_winsize( 0, 0, 0, 0 );
    ioctl( $fh, &IO::Tty::Constant::TIOCGWINSZ, $winsize )
      and ioctl( $self, &IO::Tty::Constant::TIOCSWINSZ, $winsize )
      and return 1;
    carp "clone_winsize_from: error: $!";
    return undef;
}

# ioctl() may pad the buffer beyond sizeof(struct winsize),
# so trim it before passing to unpack_winsize.
my $SIZEOF_WINSIZE = length IO::Tty::pack_winsize( 0, 0, 0, 0 );

sub get_winsize {
    my $self = shift;
    my $winsize = IO::Tty::pack_winsize( 0, 0, 0, 0 );
    ioctl( $self, IO::Tty::Constant::TIOCGWINSZ(), $winsize )
      or croak "Cannot TIOCGWINSZ - $!";
    substr( $winsize, $SIZEOF_WINSIZE ) = "";
    return IO::Tty::unpack_winsize($winsize);
}

sub set_winsize {
    my $self    = shift;
    my $winsize = IO::Tty::pack_winsize(@_);
    ioctl( $self, IO::Tty::Constant::TIOCSWINSZ(), $winsize )
      or croak "Cannot TIOCSWINSZ - $!";
}

sub set_raw($) {
    require POSIX;
    my $self = shift;
    return 1 if not POSIX::isatty($self);
    my $ttyno   = fileno($self);
    my $termios = POSIX::Termios->new;
    unless ($termios) {
        warn "set_raw: new POSIX::Termios failed: $!";
        return undef;
    }
    unless ( $termios->getattr($ttyno) ) {
        warn "set_raw: getattr($ttyno) failed: $!";
        return undef;
    }
    $termios->setiflag(0);
    $termios->setoflag(0);
    $termios->setlflag(0);
    $termios->setcflag(
        ( $termios->getcflag() & ~( &POSIX::CSIZE | &POSIX::PARENB ) )
        | &POSIX::CS8
    );
    $termios->setcc( &POSIX::VMIN,  1 );
    $termios->setcc( &POSIX::VTIME, 0 );
    unless ( $termios->setattr( $ttyno, &POSIX::TCSANOW ) ) {
        warn "set_raw: setattr($ttyno) failed: $!";
        return undef;
    }
    return 1;
}

1;

__END__

=for markdown [![testsuite](https://github.com/cpan-authors/IO-Tty/actions/workflows/testsuite.yml/badge.svg)](https://github.com/cpan-authors/IO-Tty/actions/workflows/testsuite.yml)

=head1 NAME

IO::Tty - Low-level allocate a pseudo-Tty, import constants.

=head1 VERSION

1.29

=head1 SYNOPSIS

    use IO::Tty qw(TIOCNOTTY);
    ...
    # use only to import constants, see IO::Pty to create ptys.

=head1 DESCRIPTION

C<IO::Tty> is used internally by L<IO::Pty> to create a pseudo-tty.
You wouldn't want to use it directly except to import constants, use
L<IO::Pty>.  For a list of importable constants, see
L<IO::Tty::Constant>.

Windows is now supported under the Cygwin environment, see
L<http://cygwin.com/>.

Please note that pty creation is very system-dependent.  Any modern
POSIX system should be fine.  The test suite is run via GitHub Actions
CI on Linux, macOS, FreeBSD, OpenBSD, and NetBSD.

If you have problems on your system and it is listed below, you
probably have a non-standard setup, e.g. you compiled your
Linux-kernel yourself and disabled ptys (bummer!).  Please ask your
friendly sysadmin for help.

If your system is not listed, unpack the latest version of C<IO::Tty>,
do a C<'perl Makefile.PL; make; make test; uname -a'> and report
issues at L<https://github.com/cpan-authors/IO-Tty/issues>.


=head1 PLATFORMS AND KNOWN ISSUES

C<IO::Tty> is tested via CI on Linux, macOS, FreeBSD, OpenBSD, and
NetBSD across multiple Perl versions.  It is also known to work on
AIX, Solaris/illumos, HP-UX, IRIX, z/OS, and Windows (under Cygwin).

Known platform-specific behaviors:

=over 4

=item * Linux, AIX

Returns EIO instead of EOF when the slave is closed.  Benign.

=item * FreeBSD, OpenBSD, HP-UX, Solaris

EOF on the slave tty is not reported back to the master.

=item * OpenBSD

The ioctl TIOCSCTTY sometimes fails.  This is also known in
Tcl/Expect.

=item * Solaris

Has the "feature" of returning EOF just once.

=item * Cygwin

When you send (print) a too long line (>160 chars) to a non-raw pty,
the call just hangs forever and even alarm() cannot get you out.

=back

Please report issues at
L<https://github.com/cpan-authors/IO-Tty/issues>.


=head1 SEE ALSO

L<IO::Pty>, L<IO::Tty::Constant>

Source code and issue tracker at
L<https://github.com/cpan-authors/IO-Tty>.


=head1 AUTHORS

Originally by Graham Barr E<lt>F<gbarr@pobox.com>E<gt>, based on the
Ptty module by Nick Ing-Simmons E<lt>F<nik@tiuk.ti.com>E<gt>.

Heavily rewritten by Roland Giersig
E<lt>F<RGiersig@cpan.org>E<gt>.

Currently maintained by Todd Rinaldo.

Contains copyrighted stuff from openssh v3.0p1, authored by Tatu
Ylonen <ylo@cs.hut.fi>, Markus Friedl and Todd C. Miller
<Todd.Miller@courtesan.com>.


=head1 COPYRIGHT

Now all code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Nevertheless the above AUTHORS retain their copyrights to the various
parts and want to receive credit if their source code is used.
See the source for details.


=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.

In other words: Use at your own risk.  Provided as is.  Your mileage
may vary.  Read the source, Luke!

And finally, just to be sure:

Any Use of This Product, in Any Manner Whatsoever, Will Increase the
Amount of Disorder in the Universe. Although No Liability Is Implied
Herein, the Consumer Is Warned That This Process Will Ultimately Lead
to the Heat Death of the Universe.

=cut
