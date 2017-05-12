#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;
use Linux::AtaSmart;
use Linux::AtaSmart::Constants qw/:all/;
use Try::Tiny;
use Number::Format qw/format_bytes/;

my $disk_dev = shift || die "You must supply a disk, e.g /dev/sda";

say "Open [$disk_dev]";

my $atasmart;

try {
    $atasmart = Linux::AtaSmart->new($disk_dev);
    my $bytes = $atasmart->get_size;
    say 'Size: ' . format_bytes($bytes);

    say 'Awake: ' .  ($atasmart->check_sleep_mode ? 'YES'  : 'NO');
    say 'Status: ' . ($atasmart->smart_status     ? 'GOOD' : 'BAD');

    say "Bad Sectors: " . $atasmart->get_bad;

    say "Temperature °C: " . ($atasmart->get_temperature // "N/A");

    my $status = $atasmart->get_overall;

    if ($status != OVERALL_GOOD) {
        say "STATUS NOT GOOD!";
    }

    say "Power Cycles: " . ( $atasmart->get_power_cycle // "N/A" );

    my $powered_on = $atasmart->get_power_on;

    say "Powered On: " . ( $powered_on ? $powered_on->pretty : "N/A" );
}
catch {
    say "BOOM: $_";
    exit;
};

#say "Start short test";
#$atasmart->self_test(TEST_SHORT);

#say "#### DUMP ####";
#$atasmart->dump;
#say "#### DUMP ####";
