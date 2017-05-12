# $Id: Unix.pm,v 1.1 2008/04/02 17:07:11 cvs Exp $

package #
Devel::AssertOS::Unix;

use Devel::CheckOS;

$VERSION = '1.0';

# list of OSes lifted from Module::Build 0.2808
#
sub os_is {
    $^O =~ /^(
        aix       |
        bsdos     |
        dgux      |
        dragonfly |
        dynixptx  |
        freebsd   |
        linux     |
        hpux      |
        irix      |
        darwin    |
        machten   |
        openbsd   |
        netbsd    |
        dec_osf   |
        svr4      |
        svr5      |
        sco_sv    |
        unicos    |
        unicosmk  |
        solaris   |
        sunos     |
        interix
    )$/x ? 1 : 0;
}

Devel::CheckOS::die_unsupported() unless(os_is());

1;
