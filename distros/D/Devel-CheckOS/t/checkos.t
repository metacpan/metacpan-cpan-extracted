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
sleep(2);
utime time(), time(), File::Spec->catfile(qw(t otherlib Devel AssertOS AnOperatingSystem.pm));

ok(1 == (grep { /^AnOperatingSystem$/i } Devel::CheckOS::list_platforms()),
   "A platform is listed only once");
{
    local $Devel::CheckOS::NoDeprecationWarnings::Context = 1;
    ok(Devel::CheckOS::list_platforms->{AnOperatingSystem} eq
       File::Spec->catfile(qw(t otherlib Devel AssertOS AnOperatingSystem.pm)),
       "scalar list_platforms gives the most recent module for an OS");
}

is
    warning { my $foo = Devel::CheckOS::list_platforms() },
    "Calling list_platforms in scalar context and getting back a reference is deprecated and will go away some time after April 2024. To disable this warning set \$Devel::CheckOS::NoDeprecationWarnings::Context to a true value.\n",
    "list_platforms in scalar context == warning";

done_testing;
