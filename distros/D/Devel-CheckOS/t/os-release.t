use warnings;
use strict;
use Test::More;
use Devel::CheckOS qw(os_is);
use Devel::CheckOS::Helpers::LinuxOSrelease 'distributor_id';

Devel::CheckOS::Helpers::LinuxOSrelease::_set_file('t/etc-os-release/ubuntu');
is( distributor_id, 'ubuntu', "can fetch the distribution ID when it's not quoted" );
{
    local $^O = 'linux';
    ok(os_is('Linux::Ubuntu'), "... detected Ubuntu");
}

Devel::CheckOS::Helpers::LinuxOSrelease::_set_file('t/etc-os-release/opensuse-tumbleweed');
is( distributor_id, 'opensuse-tumbleweed', "can fetch the ID when is it quoted");

done_testing;
