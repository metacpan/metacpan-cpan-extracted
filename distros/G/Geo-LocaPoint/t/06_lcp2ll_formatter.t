use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::LocaPoint;

SKIP:{
    eval "use Geo::Formatter qw(LocaPoint);";
    skip "Geo::Formatter is not installed", 2 * blocks if($@);

    run {
        my $block = shift;
        my ($locapo)           = split(/\n/,$block->input);
        my ($lat,$lng)         = split(/\n/,$block->expected);

        my ($dlat,$dlng)       = format2latlng( 'locapoint', $locapo );
        is $lat, $dlat;
        is $lng, $dlng;
    };
}

__END__
===
--- input
SD7.XC0.GF5.TT8
--- expected
35.606954
139.567104

===
--- input
JB2.IT5.AZ7.XC7
--- expected
-27.371768
-58.798831
