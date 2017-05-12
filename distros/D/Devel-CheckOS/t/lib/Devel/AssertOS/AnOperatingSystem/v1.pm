# $Id: v1.pm,v 1.2 2007/10/18 13:31:25 drhyde Exp $

package Devel::AssertOS::AnOperatingSystem::v1;

use Devel::CheckOS qw(die_unsupported);

use Devel::AssertOS::AnOperatingSystem;

$VERSION = '1.0';

sub os_is { 0; }

die_unsupported() unless(os_is());

1;
