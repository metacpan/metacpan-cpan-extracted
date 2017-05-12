use strict;
$^W = 1;

use Test::More;

END { done_testing(); }

use Devel::CheckOS ':all';

use File::Spec;
use lib File::Spec->catdir(qw(t lib));

ok(os_is('AnOperatingSystem'), "os_is imported");
ok(os_isnt('NotAnOperatingSystem'), "os_isnt imported");

eval { die_if_os_isnt('AnOperatingSystem') };
ok(!$@, "die_if_os_isnt imported");
eval { die_if_os_is('AnOperatingSystem') };
ok($@ =~ /OS unsupported/i, "die_if_os_is imported");

eval { die_unsupported() };
ok($@ =~ /OS unsupported/i, "die_unsupported imported");

ok((grep { /^AnOperatingSystem$/i } list_platforms()),
   "list_platforms imported");
