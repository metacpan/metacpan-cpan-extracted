package Devel::AssertOS::EBCDIC;

use Devel::CheckOS;
use strict;
use warnings;
no warnings 'redefine';

our $VERSION = '1.0';

# list of OSes lifted from Module::Build 0.2808
#
sub matches {
    return qw(
        OS390 OS400 POSIXBC VMESA
    );
}
sub os_is { Devel::CheckOS::os_is(matches()); }
Devel::CheckOS::die_unsupported() unless(os_is());

sub expn {
  "The OS uses some variant of EBCDIC instead of ASCII."
}

=head1 COPYRIGHT and LICENCE

Copyright 2010 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;
