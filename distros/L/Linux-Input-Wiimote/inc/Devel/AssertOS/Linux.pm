#line 1
# $Id: Linux.pm,v 1.4 2007/10/19 16:45:51 drhyde Exp $

package Devel::AssertOS::Linux;

use Devel::CheckOS;

$VERSION = '1.0';

sub os_is { $^O eq 'linux' ? 1 : 0; }

Devel::CheckOS::die_unsupported() unless(os_is());

1;
