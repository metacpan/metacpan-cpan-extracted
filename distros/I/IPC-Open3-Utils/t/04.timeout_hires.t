use Test::More;

eval 'use Time::HiRes';
if ($@) {
    plan 'skip_all' => 'Time::HiRes required for testing high resolution timeouts';
}
else {
    my $rt57663 = 0;
    diag("testing for rt57663 condition");
    alarm(100);
    my $cur = Time::HiRes::alarm(5);
    $rt57663++ if $cur == 0;
    sleep 2;
    Time::HiRes::alarm($cur);
    my $c = alarm(0);
    $rt57663++ if $cur > 90;

    if ($rt57663) {
        plan 'skip_all' => 'Time::HiRes rt57663 condition detected';
    }
    else {
        plan 'tests' => 103;
    }
}

use lib '../lib', 'lib';
chdir 't';

use_ok('IPC::Open3::Utils');

diag("Testing IPC::Open3::Utils $IPC::Open3::Utils::VERSION");
diag("Time::HiRes loaded mode");

my @cmd = qw(sleep 2);
my %test;

# 'timeout'                 => $arg_hr->{'timeout'},
# 'timeout_is_microseconds' => $arg_hr->{'timeout_is_microseconds'},
# 'Time::Hires'             => $INC{'Time/HiRes.pm'},
# 'Time::Hires::ualarm'     => defined &Time::HiRes::ualarm ? 1 : 0,
# 'Time::Hires::alarm'      => defined &Time::HiRes::alarm ? 1 : 0,
# 'original_alarm'          => $original_alarm,

diag("Whole second tests");
for my $alarm ( 0, [ 100, 90 ] ) {
    my $to_a = 5;
    my $to_b = 1;
    if ($alarm) {
        alarm( $alarm->[0] );
    }
    ok( run_cmd( @cmd, { 'timeout' => $to_a, '_timeout_info' => \%test } ), 'does not time out returns true' );
    if ($alarm) {
        my $current = alarm(0);
        ok( $current > $alarm->[1],                'existing alarm preserved' );
        ok( $test{'original_alarm'} > $alarm->[1], 'original_alarm attr' );
    }
    else {
        ok( !$test{'original_alarm'}, 'original_alarm attr' );
    }
    ok( $test{'timeout'} == $to_a,         'timeout attr' );
    ok( !$test{'timeout_is_microseconds'}, 'timeout_is_microseconds attr' );
    ok( $test{'Time::Hires'},              'Time::Hires attr' );
    ok( $test{'Time::Hires::ualarm'},      'Time::Hires::ualarm attr' );
    ok( $test{'Time::Hires::alarm'},       'Time::Hires::alarm attr' );

    if ($alarm) {
        alarm( $alarm->[0] );
    }
    ok( !run_cmd( @cmd, { 'timeout' => $to_b, '_timeout_info' => \%test } ), 'time out returns false' );
    if ($alarm) {
        my $current = alarm(0);
        ok( $@ =~ m/^Alarm clock/, 'time out sets $@ to "Alarm clock"' );
        ok( $! == 4 || $! == 60, '$! set appropriately on time out' );
        ok( $current > $alarm->[1],                'existing alarm preserved' );
        ok( $test{'original_alarm'} > $alarm->[1], 'original_alarm attr' );
    }
    else {
        ok( $@ =~ m/^Alarm clock/, 'time out sets $@ to "Alarm clock"' );
        ok( $! == 4 || $! == 60, '$! set appropriately on time out' );
        ok( !$test{'original_alarm'}, 'original_alarm attr' );
    }
    ok( $test{'timeout'} == $to_b,         'timeout attr' );
    ok( !$test{'timeout_is_microseconds'}, 'timeout_is_microseconds attr' );
    ok( $test{'Time::Hires'},              'Time::Hires attr' );
    ok( $test{'Time::Hires::ualarm'},      'Time::Hires::ualarm attr' );
    ok( $test{'Time::Hires::alarm'},       'Time::Hires::alarm attr' );
}

diag("Floating second tests");
for my $alarm ( 0, [ 100, 90 ] ) {
    my $to_a = 5.1234;
    my $to_b = 1.1234;
    if ($alarm) {
        alarm( $alarm->[0] );
    }
    ok( run_cmd( @cmd, { 'timeout' => $to_a, '_timeout_info' => \%test } ), 'does not time out returns true' );
    if ($alarm) {
        my $current = alarm(0);
        ok( $current > $alarm->[1],                'existing alarm preserved' );
        ok( $test{'original_alarm'} > $alarm->[1], 'original_alarm attr' );
    }
    else {
        ok( !$test{'original_alarm'}, 'original_alarm attr' );
    }
    ok( $test{'timeout'} == $to_a,         'timeout attr' );
    ok( !$test{'timeout_is_microseconds'}, 'timeout_is_microseconds attr' );
    ok( $test{'Time::Hires'},              'Time::Hires attr' );
    ok( $test{'Time::Hires::ualarm'},      'Time::Hires::ualarm attr' );
    ok( $test{'Time::Hires::alarm'},       'Time::Hires::alarm attr' );

    if ($alarm) {
        alarm( $alarm->[0] );
    }
    ok( !run_cmd( @cmd, { 'timeout' => $to_b, '_timeout_info' => \%test } ), 'time out returns false' );
    if ($alarm) {
        my $current = alarm(0);
        ok( $@ =~ m/^Alarm clock/, 'time out sets $@ to "Alarm clock"' );
        ok( $! == 4 || $! == 60, '$! set appropriately on time out' );
        ok( $current > $alarm->[1],                'existing alarm preserved' );
        ok( $test{'original_alarm'} > $alarm->[1], 'original_alarm attr' );
    }
    else {
        ok( $@ =~ m/^Alarm clock/, 'time out sets $@ to "Alarm clock"' );
        ok( $! == 4 || $! == 60, '$! set appropriately on time out' );
        ok( !$test{'original_alarm'}, 'original_alarm attr' );
    }
    ok( $test{'timeout'} == $to_b,         'timeout attr' );
    ok( !$test{'timeout_is_microseconds'}, 'timeout_is_microseconds attr' );
    ok( $test{'Time::Hires'},              'Time::Hires attr' );
    ok( $test{'Time::Hires::ualarm'},      'Time::Hires::ualarm attr' );
    ok( $test{'Time::Hires::alarm'},       'Time::Hires::alarm attr' );
}

diag("Microsecond tests");
for my $alarm ( 0, [ 100, 90 ] ) {
    if ($alarm) {
        alarm( $alarm->[0] );
    }
    ok( run_cmd( @cmd, { 'timeout' => 3_123_456, 'timeout_is_microseconds' => 1, '_timeout_info' => \%test } ), 'does not time out returns true' );
    if ($alarm) {
        my $current = alarm(0);
        ok( $current > $alarm->[1],                'existing alarm preserved' );
        ok( $test{'original_alarm'} > $alarm->[1], 'original_alarm attr' );
    }
    else {
        ok( !$test{'original_alarm'}, 'original_alarm attr' );
    }
    ok( $test{'timeout'} == 3_123_456,    'timeout attr' );
    ok( $test{'timeout_is_microseconds'}, 'timeout_is_microseconds attr' );
    ok( $test{'Time::Hires'},             'Time::Hires attr' );
    ok( $test{'Time::Hires::ualarm'},     'Time::Hires::ualarm attr' );
    ok( $test{'Time::Hires::alarm'},      'Time::Hires::alarm attr' );

    if ($alarm) {
        alarm( $alarm->[0] );
    }
    ok( !run_cmd( @cmd, { 'timeout' => 350_000, 'timeout_is_microseconds' => 1, '_timeout_info' => \%test } ), 'time out returns false' );
    if ($alarm) {
        my $current = alarm(0);
        ok( $@ =~ m/^Alarm clock/, 'time out sets $@ to "Alarm clock"' );
        ok( $! == 4 || $! == 60, '$! set appropriately on time out' );
        ok( $current > $alarm->[1],                'existing alarm preserved' );
        ok( $test{'original_alarm'} > $alarm->[1], 'original_alarm attr' );
    }
    else {
        ok( $@ =~ m/^Alarm clock/, 'time out sets $@ to "Alarm clock"' );
        ok( $! == 4 || $! == 60, '$! set appropriately on time out' );
        ok( !$test{'original_alarm'}, 'original_alarm attr' );
    }
    ok( $test{'timeout'} == 350_000,      'timeout attr' );
    ok( $test{'timeout_is_microseconds'}, 'timeout_is_microseconds attr' );
    ok( $test{'Time::Hires'},             'Time::Hires attr' );
    ok( $test{'Time::Hires::ualarm'},     'Time::Hires::ualarm attr' );
    ok( $test{'Time::Hires::alarm'},      'Time::Hires::alarm attr' );
}
