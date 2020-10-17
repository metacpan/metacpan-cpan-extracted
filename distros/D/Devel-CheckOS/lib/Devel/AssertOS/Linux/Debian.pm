package Devel::AssertOS::Linux::Debian;

use Devel::CheckOS;
use strict;
use warnings;
no warnings 'redefine';

our $VERSION = '1.1';

sub matches { map { "Linux::$_" } qw(Raspbian Ubuntu RealDebian UnknownDebianLike) }

sub os_is { Devel::CheckOS::os_is(matches()) }

sub expn { "The operating system is some derivative of Debian Linux (see Linux::RealDebian for *actual* Debian Linux)" }

Devel::CheckOS::die_unsupported() unless(os_is());

=head1 COPYRIGHT and LICENCE

Copyright 2007 - 2020 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;

