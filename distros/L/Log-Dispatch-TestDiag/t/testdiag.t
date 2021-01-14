#!usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use Log::Dispatch;
use Log::Dispatch::TestDiag;

###############################################################################
# Instantiation.
subtest 'Instantiation' => sub {
    my $output = Log::Dispatch::TestDiag->new(
        name      => 'diag',
        min_level => 'debug',
    );
    isa_ok $output, 'Log::Dispatch::TestDiag';
};

###############################################################################
# Instantiation via Log::Dispatch->new
subtest 'Instantiation, via Log::Dispatch' => sub {
    my $logger = Log::Dispatch->new(
        outputs => [ ['TestDiag', min_level=>'debug'] ],
    );
    isa_ok $logger, 'Log::Dispatch';
};

###############################################################################
# Logging test
subtest 'Logging' => sub {
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
};

###############################################################################
# Logging test, via "note"
subtest 'Logging, via "note"' => sub {
    my $logger = Log::Dispatch->new(
        outputs => [ ['TestDiag', min_level=>'info', as_note=>1] ],
    );

    # Over-ride Test::More::note() so we can capture test output
    my @entries;
    no warnings 'redefine';
    local *Test::More::note = sub { push @entries, shift };

    # Send some log messages
    $logger->info("info gets logged");
    $logger->debug("debug does not");
    $logger->warning("warning gets logged");

    # Verify that they got logged via (our over-ridden) Test::More::note()
    my @expected = (
        "info gets logged",
        "warning gets logged",
    );
    is_deeply \@entries, \@expected,
        'Entries logged as expected via Test::More::note';
};

###############################################################################
done_testing();
