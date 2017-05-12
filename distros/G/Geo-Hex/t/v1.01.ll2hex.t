use strict;
use Test::Base;
plan tests => 1 * blocks;
use Geo::Hex1;

run {
    my $block = shift;
    my ($lat,$lng,$level) = split(/\n/,$block->input);
    my ($hex)             = split(/\n/,$block->expected);
    $level = undef if ( $level eq '' );

    is $hex, latlng2geohex($lat,$lng,$level);
#    my ($tlat,$tlng) = japanhex2latlng($hex);
#    is $hex, latlng2japanhex($tlat, $tlng);
};

__END__
===
--- input
35.658395
139.701848
--- expected
wkmP

===
--- input
35.658305
139.700877
1
--- expected
132KpwT

===
--- input
35.658305
139.700877
15
--- expected
ff96I

===
--- input
35.658395
139.701848
60
--- expected
032Lr

===
--- input
34.692489
135.500302
7
--- expected
rmox

===
--- input
34.692489
135.500302
1
--- expected
132bBGK

===
--- input
34.692489
135.500302
15
--- expected
fcaLw

===
--- input
34.692489
135.500302
60
--- expected
032dD
