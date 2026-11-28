# MIMEDefang-smtpd-filter

[![CI](https://github.com/The-McGrail-Foundation/MIMEDefang-smtpd-filter/actions/workflows/main.yml/badge.svg)](https://github.com/The-McGrail-Foundation/MIMEDefang-smtpd-filter/actions/workflows/main.yml) [![CPAN version](https://img.shields.io/cpan/v/Mail-MIMEDefang-OpenSMTPD)](https://metacpan.org/dist/Mail-MIMEDefang-OpenSMTPD) [![GitHub license](https://img.shields.io/github/license/The-McGrail-Foundation/MIMEDefang-smtpd-filter)](https://github.com/The-McGrail-Foundation/MIMEDefang-smtpd-filter/blob/main/LICENSE) [![Last commit](https://img.shields.io/github/last-commit/The-McGrail-Foundation/MIMEDefang-smtpd-filter)](https://github.com/The-McGrail-Foundation/MIMEDefang-smtpd-filter/commits/main)

MIMEDefang-smtpd-filter is an OpenSMTPD filter to integrate MIMEDefang and OpenSMTPD.

To enable the filter just add the following lines into your smtpd.conf:

    filter "mimedefang" proc-exec "filter-mimedefang.pl" user _mdefang group _mdefang
    listen on all filter "mimedefang"

The program has some parameters to modify its behavior.

-d  enable debug mode, when debug mode is enabled, logs will be more
    verbose and temporary files under /var/spool/MIMEDefang will not be
    removed.

-r  run relay check by calling filter_relay sub in mimedefang-filter(5)

-H  run helo check by calling filter_helo sub in mimedefang-filter(5)

-s  run sender check by calling filter_sender sub in mimedefang-filter(5)

-t  run recipient check by calling filter_recipient sub in
    mimedefang-filter(5), once per recipient

-X  Do not add an X-Scanned-By: header.

-m socket  mimedefang-multiplexor(8) socket, default
    /var/spool/MIMEDefang/mimedefang-multiplexor.sock

-z dir  MIMEDefang spool directory, default /var/spool/MIMEDefang

-T secs  multiplexor timeout, default 30.  If the multiplexor cannot be
    reached mail is tempfailed with a 451.

Some features that are available in MIMEDefang are not implemented because
smtpd-filters(7) cannot do them once a message has been accepted:
add_recipient(), delete_recipient(), change_sender() and quarantining in the
MTA queue (action_sm_quarantine()) are not available.  action_discard() is ignored.

Installation:

From CPAN:

    cpan Mail::MIMEDefang::OpenSMTPD

From a source checkout or tarball:

    perl Makefile.PL
    make
    make test
    make install

filter-mimedefang.pl is installed in /usr/local/libexec/smtpd, where
smtpd(8) looks up a relative proc-exec path, and its man page as
filter-mimedefang.pl(1).  If INSTALL_BASE or PREFIX is given (for example by
local::lib), the filter goes to that tree's bin directory instead and
smtpd.conf needs its full path.  The directory can also be set explicitly:

    perl Makefile.PL INSTALLSITESCRIPT=/some/dir

The helpers are in Mail::MIMEDefang::OpenSMTPD (lib/Mail/MIMEDefang/OpenSMTPD.pm);
tests are under t/ and need Test::More, MIMEDefang and OpenSMTPd::Filter.
