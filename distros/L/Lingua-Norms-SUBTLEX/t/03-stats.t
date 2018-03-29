use strict;
use warnings;
use Test::More tests => 5;
use Statistics::Lite qw(mean median stddev);
use FindBin qw/$Bin/;
use File::Spec;
use Lingua::Norms::SUBTLEX;
require File::Spec->catfile($Bin, '_common.pl');

my $subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($Bin, qw'samples US.csv'), fieldpath =>  File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'), lang => 'US');
my $val;
my %testlist = (
    the       => { freq => 29449.18, log => 6.1766, zipf => 7.468477762 },
    to        => { freq => 22677.84 },
    Detective => { freq => 61.12,    log => 3.4939, zipf => 4.785710253 }
);

my $test_mean = mean( 29449.18, 22677.84, 61.12 );
$subtlex->set_eq(match_level => 1);
my $obs_mean = $subtlex->frq_mean( strings => [ keys %testlist ] );
ok(
    about_equal( $test_mean, $obs_mean ),
    "Frequency mean not as expected: expected $test_mean; observed: $obs_mean"
);

$obs_mean = $subtlex->frq_mean( strings => [ keys %testlist ], scale => 'log' );
$test_mean = 5.244567;
ok( about_equal( $test_mean, $obs_mean ),
    "log-frequency mean not same: expected $test_mean; observed: $obs_mean" );

$obs_mean = $subtlex->frq_mean( strings => [ keys %testlist ], scale => 'zipf' );
$test_mean = 6.536398;
ok( about_equal( $test_mean, $obs_mean ),
    "zipf-frequency mean not same: expected $test_mean; observed: $obs_mean" );

my $test_median = median( 29449.18, 22677.84, 61.12 );
my $obs_median = $subtlex->median_freq( strings => [ keys %testlist ] );
ok( about_equal( $test_median, $obs_median ),
    "median frequency not same: expected $test_median; observed: $obs_median" );

my $test_stdev = stddev( 29449.18, 22677.84, 61.12 );
my $obs_stdev = $subtlex->sd_freq( strings => [ keys %testlist ] );
ok( about_equal( $test_stdev, $obs_stdev ),
    "stdev frequency not same: expected $test_stdev; observed: $obs_stdev" );

1;
