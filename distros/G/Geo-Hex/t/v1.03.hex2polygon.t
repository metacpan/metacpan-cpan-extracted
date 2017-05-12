use strict;
use Test::Base;
plan tests => 14 * blocks;
use Geo::Hex1;

run {
    my $block = shift;
    my ($hex)  = split(/\n/,$block->input);
    my @points = split(/\n/,$block->expected);

    my @tpoints = @{geohex2polygon($hex)};

    foreach my $i ( 0..$#tpoints ) {
        my ( $lat,  $lng  ) = split(/,/,$points[$i]);
        my ( $tlat, $tlng ) = @{ $tpoints[$i] };
        is $lat,   sprintf('%.6f',$tlat);
        is $lng,   sprintf('%.6f',$tlng);
    }
};

__END__
===
--- input
wkmP
--- expected
35.654108,139.693874
35.659008,139.697374
35.659008,139.704374
35.654108,139.707874
35.649208,139.704374
35.649208,139.697374
35.654108,139.693874

