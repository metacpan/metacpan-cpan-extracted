package Devel::AssertOS::Linux::UnknownDebianLike;

use Devel::CheckOS;
use strict;
use warnings;
no warnings 'redefine';

our $VERSION = '1.0';

# Can't use() this because that would make an infinite loop at BEGIN-time
if(!exists($INC{'Devel/AssertOS/Linux/Debian.pm'})) {
    require Devel::AssertOS::Linux::Debian;
}

sub os_is {
    Devel::CheckOS::os_is('Linux') &&
    -f '/etc/debian_version' &&
    Devel::CheckOS::os_isnt(grep { $_ !~ /UnknownDebianLike/ } Devel::AssertOS::Linux::Debian::matches())
}

sub expn { "The operating system is some derivative of Debian, or possibly a very old version of real Debian" }

Devel::CheckOS::die_unsupported() unless(os_is());

=head1 COPYRIGHT and LICENCE

Copyright 2024 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;

