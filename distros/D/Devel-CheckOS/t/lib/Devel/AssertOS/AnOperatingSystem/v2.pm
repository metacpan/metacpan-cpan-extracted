# $Id: v2.pm,v 1.1 2007/10/18 13:29:34 drhyde Exp $

package Devel::AssertOS::AnOperatingSystem::v2;

use Devel::CheckOS qw(die_unsupported);

use Devel::AssertOS::AnOperatingSystem;

$VERSION = '1.0';

sub os_is { 1; }

die_unsupported() unless(os_is());

1;
