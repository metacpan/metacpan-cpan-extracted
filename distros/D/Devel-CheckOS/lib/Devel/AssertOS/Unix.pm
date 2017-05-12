package Devel::AssertOS::Unix;

use Devel::CheckOS;
use strict;
use warnings;
no warnings 'redefine';

our $VERSION = '1.6';

# list of OSes originally lifted from Module::Build 0.2808
#
sub matches {
    return qw(
        AIX Android Bitrig BSDOS DGUX DragonflyBSD Dynix FreeBSD HPUX Hurd
        Interix iOS Irix Linux MachTen MacOSX Minix MirOSBSD NetBSD OpenBSD OSF
        QNX SCO Solaris SunOS SysVr4 SysVr5 Unicos MidnightBSD
    );
}
sub os_is { Devel::CheckOS::os_is(matches()); }
Devel::CheckOS::die_unsupported() unless(os_is());

sub expn {
join("\n", 
"The OS supports multiple concurrent users, devices are represented as",
"pseudo-files in /dev, there is a single root to the filesystem, users",
"are protected from interference from other users, and the API is POSIXy.",
"It should be reasonably easy to port a simple text-mode C program",
"between Unixes.\n",
"In some cases (eg Android, iOS) this might not be obvious or be exposed",
"to users."
)
}

=head1 COPYRIGHT and LICENCE

Copyright 2007 - 2014 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;
