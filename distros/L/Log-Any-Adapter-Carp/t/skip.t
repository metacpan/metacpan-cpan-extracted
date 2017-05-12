#!/usr/bin/env perl

use Test::More;

use Log::Any::Adapter;

my $logfile = $0 . ' line ';
my ( $logline, $msg );
$SIG{__WARN__} = sub { $msg = shift; };

package My::Test::TraceMe;

use Log::Any;

sub test_log {
    Log::Any::Adapter->set( 'Carp', full_trace => 1, log_level => 'warn' );
    Log::Any->get_logger->warn('Full trace');
}

package My::Test::SkipMe;

use Log::Any qw($log);
Log::Any::Adapter->set( 'Carp', skip_me => 1, log_level => 'warn' );

sub test_log {
    $log->warn('Skipping me');
}

sub test_here {
    $logline = __LINE__ + 1;
    $log->warn('Skipping packages');
}

sub test_full_log {
    My::Test::TraceMe::test_log();
}

package My::Trial::LogMe;

sub test_log {
    Log::Any::Adapter->set(
        'Carp',
        log_level     => 'warn',
        skip_packages => qr/^My::Test::/
    );
    $logline = __LINE__ + 1;
    Log::Any->get_logger->warn('Outside clan');

}

sub test_full_log {
    Log::Any::Adapter->set(
        'Carp',
        log_level     => 'warn',
        full_trace    => 1,
        skip_packages => qr/^My::Test::/    # now useless
    );
    Log::Any->get_logger->warn('Outside clan');

}

package My::Test::LogMe;

sub test_log {
    $logline = __LINE__ + 1;
    My::Test::SkipMe::test_log();
}

sub test_here {
    My::Test::SkipMe::test_here();
}

sub test_clan {
    $logline = __LINE__ + 1;
    My::Trial::LogMe::test_log();
}

sub test_full_clan {
    My::Trial::LogMe::test_full_log();
}

package main;

My::Test::LogMe::test_log();
like( $msg, qr/Skipping me at $logfile$logline/, 'Skip me' );

Log::Any::Adapter->set(
    'Carp',
    log_level     => 'warn',
    skip_packages => [ 'My::Test::SkipMe', 'My::Test::LogMe' ]
);
My::Test::LogMe::test_here();
$logline = __LINE__ - 1;
like( $msg, qr/Skipping packages at $logfile$logline/s, 'Skip packages' );

Log::Any::Adapter->set(
    'Carp',
    log_level     => 'warn',
    skip_packages => 'My::Test::SkipMe'
);
$logline = __LINE__ + 1;
My::Test::LogMe::test_log();
like( $msg, qr/Skipping me at $logfile$logline/s, 'Skip single package' );

Log::Any::Adapter->set(
    'Carp',
    log_level     => 'warn',
    skip_packages => 'My::Missing::SkipMe'
);
My::Test::LogMe::test_here();
like( $msg, qr/Skipping packages at $logfile$logline/s,
    'Skip missing package' );

$logline = __LINE__ + 1;
My::Test::SkipMe::test_full_log();
like( $msg, qr/Full trace at.*My::Test::SkipMe.*$logfile$logline/s,
    'Full trace' );

SKIP: {
    eval { require Carp::Clan; };
    skip 'Carp::Clan not installed', 2 if $@;

    My::Test::LogMe::test_clan();
    like( $msg, qr/Outside clan at $logfile$logline/, 'Clan' );

    $logline = __LINE__ + 1;
    My::Test::LogMe::test_full_clan();
    like(
        $msg,
        qr/Outside clan at.*My::Test::.*$logfile$logline/s,
        'Full trace via Clan'
    );

}

done_testing();
