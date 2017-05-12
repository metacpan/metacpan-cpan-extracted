#!usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;
use Log::Dispatch;
use Log::Dispatch::TestDiag;

###############################################################################
# Instantiation.
instantiation: {
    my $output = Log::Dispatch::TestDiag->new(
        name      => 'diag',
        min_level => 'debug',
    );
    isa_ok $output, 'Log::Dispatch::TestDiag';
}

###############################################################################
# Instantiation via Log::Dispatch->new
instantiation_via_log_dispatch: {
    my $logger = Log::Dispatch->new(
        outputs => [ ['TestDiag', min_level=>'debug'] ],
    );
    isa_ok $logger, 'Log::Dispatch';
}

###############################################################################
# Logging test
logging_test: {
    my $logger = Log::Dispatch->new(
        outputs => [ ['TestDiag', min_level=>'info'] ],
    );

    # Over-ride Test::More::diag() so we can capture test output
    my @entries;
    no warnings 'redefine';
    local *Test::More::diag = sub { push @entries, shift };

    # Send some log messages
    $logger->info("info gets logged");
    $logger->debug("debug does not");
    $logger->warning("warning gets logged");

    # Verify that they got logged via (our over-ridden) Test::More::diag()
    my @expected = (
        "info gets logged",
        "warning gets logged",
    );
    is_deeply \@entries, \@expected,
        'Entries logged as expected via Test::More::diag';
}
