use warnings;
use strict;
use Test::More;
use Devel::CheckOS qw(os_is os_isnt);
use Devel::CheckOS::Helpers::LinuxOSrelease 'distributor_id';

local $^O = 'linux';

Devel::CheckOS::Helpers::LinuxOSrelease::_set_file('t/etc-os-release/sles');
ok(os_is('Linux::SLES'), "detected SLES");
ok(os_is('Linux::SUSE'), "... and also as SUSE");
ok(os_isnt('Linux::OpenSUSE'), "... but not as OpenSUSE");

Devel::CheckOS::Helpers::LinuxOSrelease::_set_file('t/etc-os-release/opensuse-tumbleweed');
ok(os_is('Linux::OpenSUSE'), "detected tumbleweed as OpenSUSE");
ok(os_is('Linux::SUSE'), "... and also as SUSE");
ok(os_isnt('Linux::SLES'), "... but not as SLES");

Devel::CheckOS::Helpers::LinuxOSrelease::_set_file('t/etc-os-release/opensuse-leap');
ok(os_is('Linux::OpenSUSE'), "detected leap as OpenSUSE");
ok(os_is('Linux::SUSE'), "... and also as SUSE");

done_testing;
