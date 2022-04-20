use strict;
$^W = 1;

use Test::More;

use Devel::CheckOS ':booleans';

use File::Spec;
use lib File::Spec->catdir(qw(t lib));

ok(os_is('AnOperatingSystem'), "os_is imported");
ok(os_isnt('NotAnOperatingSystem'), "os_isnt imported");

done_testing;
