use strict;
use Test::Base;
plan 'no_plan';
use Geo::Hex1;

run {
    my $block = shift;
    my ($hex,$dist)  = split(/\n/,$block->input);
    my @geohexes      = split(/\n/,$block->expected);

    my @tgeohexes     = @{distance2geohexes($hex,$dist)};
    my %geohexes = map { $_ => 1 } @geohexes;

    for my $tgeohex ( @tgeohexes ) {
        is delete $geohexes{$tgeohex}, 1, "Testing $tgeohex";
    }
    
    foreach my $key ( keys %geohexes ) {
        die "Some hexes are not tested: $key";
    }
};

__END__
===
--- input
8sijg
1
--- expected
8sijh
8siig
8siif
8sijf
8sikg
8sikh

===
--- input
8sijg
2
--- expected
8sijh
8siig
8siif
8sijf
8sikg
8sikh
8sili
8siki
8siji
8siih
8sihg
8sihf
8sihe
8siie
8sije
8sikf
8silg
8silh
