use strict;
use warnings;

use Test::Most;

use GitHub::MergeVelocity::Repository::Statistics;

my $report = GitHub::MergeVelocity::Repository::Statistics->new(
    closed         => 1,
    closed_age     => 10,
    open           => 1,
    open_age       => 20,
    merged         => 0,
    merged_age     => 0,
    total_velocity => 100,
);

is( $report->percentage_in_state('closed'), '0.5', 'closed %' );
is( $report->percentage_in_state('merged'), '0',   'merged %' );
is( $report->percentage_in_state('open'),   '0.5', 'open %' );

done_testing();
