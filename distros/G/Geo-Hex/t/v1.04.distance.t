use strict;
use Test::Base;
plan tests => 1 * blocks;
use Geo::Hex1;

run {
    my $block = shift;
    my ($hex1,$hex2)  = split(/\n/,$block->input);
    my ($dist)        = split(/\n/,$block->expected);

    my $tdist = geohex2distance($hex1,$hex2);

    is $dist, $tdist;
};

__END__
===
--- input
wknR
wkoR
--- expected
1

===
--- input
wknR
wkoS
--- expected
1

===
--- input
wknR
wknS
--- expected
1

===
--- input
wknR
wkmR
--- expected
1

===
--- input
wknR
wkmQ
--- expected
1

===
--- input
wknR
wknQ
--- expected
1

===
--- input
wknR
wkmO
--- expected
3

===
--- input
wknR
wklS
--- expected
3

===
--- input
8sikg
8sihc
--- expected
4
