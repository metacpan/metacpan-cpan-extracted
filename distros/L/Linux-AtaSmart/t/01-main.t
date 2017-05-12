#!/usr/bin/env perl -w

use Test::More;

# TODO test failure conditions

if ($^O ne 'linux') {
    plan skip_all => 'Only usable on Linux.';
} elsif ($> != 0 && !exists $ENV{ATASMART_NON_ROOT}) {

    # euid == 0 or set CAP_RAW_IO on the perl binary
    plan skip_all => 'Need root to query SMART.';
} elsif (!defined $ENV{ATASMART_DEVICE}) {
    plan skip_all => 'Set ATASMART_DEVICE=/dev/xxx for tests';
} else {
    plan tests => 10;
}

use Linux::AtaSmart;

my $disk_dev = $ENV{ATASMART_DEVICE};

my $atasmart = new_ok('Linux::AtaSmart' => [$disk_dev]);
SKIP: {
    skip "SMART is NOT available for $disk_dev", 9 unless $atasmart;
    ok($atasmart->get_size,         'retrieve disk size');
    ok($atasmart->check_sleep_mode, 'check sleep mode');
    ok($atasmart->smart_status,     'basic SMART status');
    cmp_ok($atasmart->get_bad, '>=', 0, 'get number of bad sectors');
    ok($atasmart->get_temperature, 'get temperature');
    cmp_ok($atasmart->get_overall, '>=', 0, 'overall SMART status');
    ok($atasmart->get_power_cycle, 'number of power cycles');
    ok(my $power_on = $atasmart->get_power_on, 'total powered-on time...');
    isa_ok($power_on, 'Time::Seconds', '... as Time::Seconds');
}
