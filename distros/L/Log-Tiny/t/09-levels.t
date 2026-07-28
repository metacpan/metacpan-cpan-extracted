#!perl

use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
	use_ok( 'Log::Tiny' );
}

my $buf = '';
open( my $fh, '>>', \$buf ) or die $!;
my $log = Log::Tiny->new( $fh, "%c\n" ) or die Log::Tiny->errstr;

# No filtering until configured: everything logs.
$log->DEBUG("x");
is( $buf, "DEBUG\n", "Without a threshold, all categories log" );

$log->levels( [qw(DEBUG INFO WARN ERROR FATAL)] );
is( $log->min_level('WARN'), 'WARN', "min_level() setter returns the level" );
is( $log->min_level, 'WARN', "min_level() getter returns current threshold" );

$buf = '';
$log->DEBUG("a");   # below threshold -> dropped
$log->INFO("b");    # below threshold -> dropped
$log->WARN("c");    # at threshold   -> logged
$log->ERROR("d");   # above          -> logged
$log->FATAL("e");   # above          -> logged
$log->AUDIT("f");   # unranked       -> always logged
is( $buf, "WARN\nERROR\nFATAL\nAUDIT\n",
    "Below-threshold dropped; at/above and unranked kept" );

# Case-insensitive level names.
$buf = '';
is( $log->min_level('error'), 'ERROR', "min_level is case-insensitive" );
$log->WARN("g");    # now below threshold
$log->ERROR("h");
is( $buf, "ERROR\n", "Raising the threshold drops WARN" );

# Error handling.
is( $log->min_level('NOPE'), undef, "Unknown level returns undef" );

undef $log;
close $fh;
