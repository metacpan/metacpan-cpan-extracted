# rt79044_multiple.t

# this is to test for the problem described in RT #79044

use strict;
use Test::More;

use_ok('HTML::Scrubber');

use HTML::Scrubber;
my @allow    = qw[ p ];
my $scrubber = HTML::Scrubber->new();
$scrubber->allow(@allow);

ok( $scrubber, "got scrubber" );

# all of these should go through unscathed
my @data = ( '<p>one</p>', '<p>two</p>', '<p>three</p>', '<p>four</p>' );

foreach my $datum (@data) {
    is( $scrubber->scrub($datum), $datum, 'Test unscathed' );
}

# now do the same thing again, this time not allowing a <p> tag
$scrubber->allow();

foreach my $datum (@data) {
    my $result = $datum;
    $datum =~ s|</?p>||g;    # strip with regexp - yay!
    is( $scrubber->scrub($datum), $datum, 'Test processed' );
}

done_testing;
