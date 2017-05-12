use strict;
use warnings;
use Test::More tests => 5;
use constant EPS     => 1e-3;
use Statistics::Lite qw(mean median stddev);
use File::Spec;
use FindBin;
use Lingua::Norms::SUBTLEX;
my $subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($FindBin::Bin, 'US_sample.csv'), fieldpath =>  File::Spec->catfile($FindBin::Bin, '..', 'lib', 'Lingua', 'Norms', 'SUBTLEX', 'fields.csv'));
my $val;
my %testlist = (
    the       => { freq => 29449.18, log => 6.1766, zipf => 7.468477762 },
    to        => { freq => 22677.84 },
    Detective => { freq => 61.12,    log => 3.4939, zipf => 4.785710253 }
);

my $test_mean = mean( 29449.18, 22677.84, 61.12 );
my $obs_mean = $subtlex->mean_freq( strings => [ keys %testlist ] );
ok(
    about_equal( $test_mean, $obs_mean ),
    "Frequency mean not as expected: expected $test_mean; observed: $obs_mean"
);

$obs_mean = $subtlex->mean_freq( strings => [ keys %testlist ], scale => 'log' );
$test_mean = 5.244567;
ok( about_equal( $test_mean, $obs_mean ),
    "log-frequency mean not same: expected $test_mean; observed: $obs_mean" );

$obs_mean = $subtlex->mean_freq( strings => [ keys %testlist ], scale => 'zipf' );
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

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
