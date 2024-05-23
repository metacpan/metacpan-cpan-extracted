use warnings;
use strict;
use Test::More;
use Devel::CheckOS qw(os_is os_isnt);
use Devel::CheckOS::Helpers::LinuxOSrelease 'distributor_id';

local $^O = 'linux';

my @candidates = qw(RHEL Fedora Centos Alma Rocky Oracle);

foreach my $candidate (@candidates) {
    Devel::CheckOS::Helpers::LinuxOSrelease::_set_file('t/etc-os-release/'.lc($candidate));
    ok(os_is("Linux::$candidate"), "detected $candidate");
    ok(os_is('Linux::Redhat'), "... and also as Redhat");
    foreach my $not_candidate (grep { $_ ne $candidate } @candidates) {
        ok(os_isnt("Linux::$not_candidate"), "... and not as $not_candidate");
    }
}

done_testing;
