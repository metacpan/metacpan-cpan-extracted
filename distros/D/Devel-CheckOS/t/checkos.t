use strict;
$^W = 1;

use Test::More;
use Test::Warnings qw(warning);

BEGIN { use_ok('Devel::CheckOS'); }

use File::Spec;
use lib File::Spec->catdir(qw(t lib));

eval 'Devel::CheckOS::os_is("[broken]")';
ok($@ =~ /isn't a legal OS name/, "os_is whines about illegal names");

ok(Devel::CheckOS::os_is('AnOperatingSystem'),
   "a single valid OS detected by os_is");
ok(!Devel::CheckOS::os_is('NotAnOperatingSystem'),
   "a single invalid OS detected by os_is");
ok(Devel::CheckOS::os_isnt('NotAnOperatingSystem'),
   "a single invalid OS detectedby os_isnt");
ok(!Devel::CheckOS::os_isnt('AnOperatingSystem'),
   "a single valid OS detectedby os_isnt");

eval { Devel::CheckOS::die_if_os_isnt('AnOperatingSystem') };
ok(!$@, "a single valid OS detected using die_if_os_isnt");
eval { Devel::CheckOS::die_if_os_is('AnOperatingSystem') };
ok($@ =~ /OS unsupported/i, "a single valid OS detected using die_if_os_is");

eval { Devel::CheckOS::die_if_os_is('NotAnOperatingSystem') };
ok(!$@, "a single invalid OS detected using die_if_os_is");
eval { Devel::CheckOS::die_if_os_isnt('NotAnOperatingSystem') };
ok($@ =~ /OS unsupported/i, "a single invalid OS detected using die_if_os_isnt");

eval { Devel::CheckOS::die_unsupported() };
ok($@ =~ /OS unsupported/i, "die_unsupported works");

ok((grep { /^AnOperatingSystem$/i } Devel::CheckOS::list_platforms()) &&
   (grep { /^NotAnOperatingSystem$/i } Devel::CheckOS::list_platforms()),
   "list_platforms works");

ok(!(grep { /^Alias::MacOS$/i } Devel::CheckOS::list_platforms()),
   "list_platforms excludes Aliases");

eval "use lib File::Spec->catdir(qw(t otherlib))";

is(1, (grep { /^AnOperatingSystem$/i } Devel::CheckOS::list_platforms()),
   "A platform is listed only once");

done_testing;
