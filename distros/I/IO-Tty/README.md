[![testsuite](https://github.com/cpan-authors/IO-Tty/actions/workflows/testsuite.yml/badge.svg)](https://github.com/cpan-authors/IO-Tty/actions/workflows/testsuite.yml)

# NAME

IO::Tty - Low-level allocate a pseudo-Tty, import constants.

# VERSION

1.29

# SYNOPSIS

    use IO::Tty qw(TIOCNOTTY);
    ...
    # use only to import constants, see IO::Pty to create ptys.

# DESCRIPTION

`IO::Tty` is used internally by [IO::Pty](https://metacpan.org/pod/IO%3A%3APty) to create a pseudo-tty.
You wouldn't want to use it directly except to import constants, use
[IO::Pty](https://metacpan.org/pod/IO%3A%3APty).  For a list of importable constants, see
[IO::Tty::Constant](https://metacpan.org/pod/IO%3A%3ATty%3A%3AConstant).

Windows is now supported under the Cygwin environment, see
[http://cygwin.com/](http://cygwin.com/).

Please note that pty creation is very system-dependent.  Any modern
POSIX system should be fine.  The test suite is run via GitHub Actions
CI on Linux, macOS, FreeBSD, OpenBSD, and NetBSD.

If you have problems on your system and it is listed below, you
probably have a non-standard setup, e.g. you compiled your
Linux-kernel yourself and disabled ptys (bummer!).  Please ask your
friendly sysadmin for help.

If your system is not listed, unpack the latest version of `IO::Tty`,
do a `'perl Makefile.PL; make; make test; uname -a'` and report
issues at [https://github.com/cpan-authors/IO-Tty/issues](https://github.com/cpan-authors/IO-Tty/issues).

# PLATFORMS AND KNOWN ISSUES

`IO::Tty` is tested via CI on Linux, macOS, FreeBSD, OpenBSD, and
NetBSD across multiple Perl versions.  It is also known to work on
AIX, Solaris/illumos, HP-UX, IRIX, z/OS, and Windows (under Cygwin).

Known platform-specific behaviors:

- Linux, AIX

    Returns EIO instead of EOF when the slave is closed.  Benign.

- FreeBSD, OpenBSD, HP-UX, Solaris

    EOF on the slave tty is not reported back to the master.

- OpenBSD

    The ioctl TIOCSCTTY sometimes fails.  This is also known in
    Tcl/Expect.

- Solaris

    Has the "feature" of returning EOF just once.

- Cygwin

    When you send (print) a too long line (>160 chars) to a non-raw pty,
    the call just hangs forever and even alarm() cannot get you out.

Please report issues at
[https://github.com/cpan-authors/IO-Tty/issues](https://github.com/cpan-authors/IO-Tty/issues).

# SEE ALSO

[IO::Pty](https://metacpan.org/pod/IO%3A%3APty), [IO::Tty::Constant](https://metacpan.org/pod/IO%3A%3ATty%3A%3AConstant)

Source code and issue tracker at
[https://github.com/cpan-authors/IO-Tty](https://github.com/cpan-authors/IO-Tty).

# AUTHORS

Originally by Graham Barr <`gbarr@pobox.com`>, based on the
Ptty module by Nick Ing-Simmons <`nik@tiuk.ti.com`>.

Heavily rewritten by Roland Giersig
<`RGiersig@cpan.org`>.

Currently maintained by Todd Rinaldo.

Contains copyrighted stuff from openssh v3.0p1, authored by Tatu
Ylonen <ylo@cs.hut.fi>, Markus Friedl and Todd C. Miller
<Todd.Miller@courtesan.com>.

# COPYRIGHT

Now all code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Nevertheless the above AUTHORS retain their copyrights to the various
parts and want to receive credit if their source code is used.
See the source for details.

# DISCLAIMER

THIS SOFTWARE IS PROVIDED \`\`AS IS'' AND ANY EXPRESS OR IMPLIED
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
