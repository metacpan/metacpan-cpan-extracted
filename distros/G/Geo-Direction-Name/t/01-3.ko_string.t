use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::Direction::Name;

BEGIN
{
    if ( $] >= 5.006 )
    {
        require utf8; import utf8;
    }
}

run {
    my $block       = shift;
    my ($dir,$dev)  = split(/\n/,$block->input);
    my ($str)       = split(/\n/,$block->expected);

    my $dobj        = Geo::Direction::Name->new("ko_KR");

    is $dobj->to_string($dir,{ devide => $dev, abbreviation => 0 }) ,$str;
    is $dobj->to_string($dir,{ devide => $dev, abbreviation => 1 }) ,$str;
};

__END__
===
--- input
0.000
4
--- expected
북

===
--- input
0.000
8
--- expected
북

===
--- input
0.000
16
--- expected
북

===
--- input
0.000
32
--- expected
북

===
--- input
11.250
4
--- expected
북

===
--- input
11.250
8
--- expected
북

===
--- input
11.250
16
--- expected
북북동

===
--- input
11.250
32
--- expected
북미동

===
--- input
22.500
4
--- expected
북

===
--- input
22.500
8
--- expected
북동

===
--- input
22.500
16
--- expected
북북동

===
--- input
22.500
32
--- expected
북북동

===
--- input
33.750
4
--- expected
북

===
--- input
33.750
8
--- expected
북동

===
--- input
33.750
16
--- expected
북동

===
--- input
33.750
32
--- expected
북동미북

===
--- input
45.000
4
--- expected
동

===
--- input
45.000
8
--- expected
북동

===
--- input
45.000
16
--- expected
북동

===
--- input
45.000
32
--- expected
북동

===
--- input
56.250
4
--- expected
동

===
--- input
56.250
8
--- expected
북동

===
--- input
56.250
16
--- expected
동북동

===
--- input
56.250
32
--- expected
북동미동

===
--- input
67.500
4
--- expected
동

===
--- input
67.500
8
--- expected
동

===
--- input
67.500
16
--- expected
동북동

===
--- input
67.500
32
--- expected
동북동

===
--- input
78.750
4
--- expected
동

===
--- input
78.750
8
--- expected
동

===
--- input
78.750
16
--- expected
동

===
--- input
78.750
32
--- expected
동미북

===
--- input
90.000
4
--- expected
동

===
--- input
90.000
8
--- expected
동

===
--- input
90.000
16
--- expected
동

===
--- input
90.000
32
--- expected
동

===
--- input
101.250
4
--- expected
동

===
--- input
101.250
8
--- expected
동

===
--- input
101.250
16
--- expected
동남동

===
--- input
101.250
32
--- expected
동미남

===
--- input
112.500
4
--- expected
동

===
--- input
112.500
8
--- expected
남동

===
--- input
112.500
16
--- expected
동남동

===
--- input
112.500
32
--- expected
동남동

===
--- input
123.750
4
--- expected
동

===
--- input
123.750
8
--- expected
남동

===
--- input
123.750
16
--- expected
남동

===
--- input
123.750
32
--- expected
남동미동

===
--- input
135.000
4
--- expected
남

===
--- input
135.000
8
--- expected
남동

===
--- input
135.000
16
--- expected
남동

===
--- input
135.000
32
--- expected
남동

===
--- input
146.250
4
--- expected
남

===
--- input
146.250
8
--- expected
남동

===
--- input
146.250
16
--- expected
남남동

===
--- input
146.250
32
--- expected
남동미남

===
--- input
157.500
4
--- expected
남

===
--- input
157.500
8
--- expected
남

===
--- input
157.500
16
--- expected
남남동

===
--- input
157.500
32
--- expected
남남동

===
--- input
168.750
4
--- expected
남

===
--- input
168.750
8
--- expected
남

===
--- input
168.750
16
--- expected
남

===
--- input
168.750
32
--- expected
남미동

===
--- input
180.000
4
--- expected
남

===
--- input
180.000
8
--- expected
남

===
--- input
180.000
16
--- expected
남

===
--- input
180.000
32
--- expected
남

===
--- input
191.250
4
--- expected
남

===
--- input
191.250
8
--- expected
남

===
--- input
191.250
16
--- expected
남남서

===
--- input
191.250
32
--- expected
남미서

===
--- input
202.500
4
--- expected
남

===
--- input
202.500
8
--- expected
남서

===
--- input
202.500
16
--- expected
남남서

===
--- input
202.500
32
--- expected
남남서

===
--- input
213.750
4
--- expected
남

===
--- input
213.750
8
--- expected
남서

===
--- input
213.750
16
--- expected
남서

===
--- input
213.750
32
--- expected
남서미남

===
--- input
225.000
4
--- expected
서

===
--- input
225.000
8
--- expected
남서

===
--- input
225.000
16
--- expected
남서

===
--- input
225.000
32
--- expected
남서

===
--- input
236.250
4
--- expected
서

===
--- input
236.250
8
--- expected
남서

===
--- input
236.250
16
--- expected
서남서

===
--- input
236.250
32
--- expected
남서미서

===
--- input
247.500
4
--- expected
서

===
--- input
247.500
8
--- expected
서

===
--- input
247.500
16
--- expected
서남서

===
--- input
247.500
32
--- expected
서남서

===
--- input
258.750
4
--- expected
서

===
--- input
258.750
8
--- expected
서

===
--- input
258.750
16
--- expected
서

===
--- input
258.750
32
--- expected
서미남

===
--- input
270.000
4
--- expected
서

===
--- input
270.000
8
--- expected
서

===
--- input
270.000
16
--- expected
서

===
--- input
270.000
32
--- expected
서

===
--- input
281.250
4
--- expected
서

===
--- input
281.250
8
--- expected
서

===
--- input
281.250
16
--- expected
서북서

===
--- input
281.250
32
--- expected
서미북

===
--- input
292.500
4
--- expected
서

===
--- input
292.500
8
--- expected
북서

===
--- input
292.500
16
--- expected
서북서

===
--- input
292.500
32
--- expected
서북서

===
--- input
303.750
4
--- expected
서

===
--- input
303.750
8
--- expected
북서

===
--- input
303.750
16
--- expected
북서

===
--- input
303.750
32
--- expected
북서미서

===
--- input
315.000
4
--- expected
북

===
--- input
315.000
8
--- expected
북서

===
--- input
315.000
16
--- expected
북서

===
--- input
315.000
32
--- expected
북서

===
--- input
326.250
4
--- expected
북

===
--- input
326.250
8
--- expected
북서

===
--- input
326.250
16
--- expected
북북서

===
--- input
326.250
32
--- expected
북서미북

===
--- input
337.500
4
--- expected
북

===
--- input
337.500
8
--- expected
북

===
--- input
337.500
16
--- expected
북북서

===
--- input
337.500
32
--- expected
북북서

===
--- input
348.750
4
--- expected
북

===
--- input
348.750
8
--- expected
북

===
--- input
348.750
16
--- expected
북

===
--- input
348.750
32
--- expected
북미서

===
--- input
360.000
4
--- expected
북

===
--- input
360.000
8
--- expected
북

===
--- input
360.000
16
--- expected
북

===
--- input
360.000
32
--- expected
북

