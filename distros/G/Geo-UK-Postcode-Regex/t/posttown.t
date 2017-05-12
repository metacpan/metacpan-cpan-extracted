use Test::More;

use strict;
use warnings;

use Geo::UK::Postcode::Regex;

my $pkg = 'Geo::UK::Postcode::Regex';

note "outcode_to_posttowns";

my %tests = (
    AB10 => [qw/ ABERDEEN /],
    AL7  => [ 'WELWYN', 'WELWYN GARDEN CITY' ],
);

foreach my $pc ( sort keys %tests ) {

    is_deeply [ $pkg->outcode_to_posttowns($pc) ], $tests{$pc},
        "posttowns for $pc ok";
}

note "posttown_to_outcodes";

%tests = ( ABERDEEN =>
        [qw/ AB10 AB11 AB12 AB15 AB16 AB21 AB22 AB23 AB24 AB25 AB99 /], );

foreach my $pt ( sort keys %tests ) {

    is_deeply [ $pkg->posttown_to_outcodes($pt) ], $tests{$pt},
        "outcodes for $pt ok";
}

done_testing();

