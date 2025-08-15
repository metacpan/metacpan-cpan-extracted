#!/usr/bin/env perl

use 5.018;
use warnings;
use Test::More;
use Log::Any::Test;
use Log::Any '$log',
    default_adapter => [
        'MacOS::OSLog',
        subsystem => 'com.example.perl',
        log_level => 'trace',
    ];
use Log::Any::Adapter::Util qw(logging_methods);

plan tests => 2 + scalar logging_methods();

isa_ok( $log, 'Log::Any::Proxy', 'created log object' );
can_ok(
    $log,
    map { $_, "${_}f", "is_$_" }
        qw(
        trace
        debug
        info
        notice
        warning
        error
        critical
        alert
        emergency
        ) );

for my $method ( logging_methods() ) {
    $log->$method("$method message");

    is_deeply(
        $log->msgs,
        [ { message  => "$method message",
            level    => $method,
            category => 'main',
        } ],
        "$method message logged",
    ) or diag( $log->msgs );

    $log->clear();
}
