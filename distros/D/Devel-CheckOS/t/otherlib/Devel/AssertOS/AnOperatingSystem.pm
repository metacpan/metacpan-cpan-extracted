package Devel::AssertOS::AnOperatingSystem;

use Devel::CheckOS qw(die_unsupported);

$VERSION = '1.0';

sub os_is { 1; }

die_unsupported() unless(os_is());

1;
