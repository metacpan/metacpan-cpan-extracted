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
    my ($str,$abbr) = split(/\n/,$block->expected);

    my $dobj        = Geo::Direction::Name->new;

    is $dobj->to_string($dir,{ devide => $dev, abbreviation => 0 }) ,$str;
    is $dobj->to_string($dir,{ devide => $dev, abbreviation => 1 }) ,$abbr;
};

__END__
===
--- input
0.000
4
--- expected
North
N

===
--- input
0.000
8
--- expected
North
N

===
--- input
0.000
16
--- expected
North
N

===
--- input
0.000
32
--- expected
North
N

===
--- input
11.250
4
--- expected
North
N

===
--- input
11.250
8
--- expected
North
N

===
--- input
11.250
16
--- expected
North-northeast
NNE

===
--- input
11.250
32
--- expected
North by east
NbE

===
--- input
22.500
4
--- expected
North
N

===
--- input
22.500
8
--- expected
Northeast
NE

===
--- input
22.500
16
--- expected
North-northeast
NNE

===
--- input
22.500
32
--- expected
North-northeast
NNE

===
--- input
33.750
4
--- expected
North
N

===
--- input
33.750
8
--- expected
Northeast
NE

===
--- input
33.750
16
--- expected
Northeast
NE

===
--- input
33.750
32
--- expected
Northeast by north
NEbN

===
--- input
45.000
4
--- expected
East
E

===
--- input
45.000
8
--- expected
Northeast
NE

===
--- input
45.000
16
--- expected
Northeast
NE

===
--- input
45.000
32
--- expected
Northeast
NE

===
--- input
56.250
4
--- expected
East
E

===
--- input
56.250
8
--- expected
Northeast
NE

===
--- input
56.250
16
--- expected
East-northeast
ENE

===
--- input
56.250
32
--- expected
Northeast by east
NEbE

===
--- input
67.500
4
--- expected
East
E

===
--- input
67.500
8
--- expected
East
E

===
--- input
67.500
16
--- expected
East-northeast
ENE

===
--- input
67.500
32
--- expected
East-northeast
ENE

===
--- input
78.750
4
--- expected
East
E

===
--- input
78.750
8
--- expected
East
E

===
--- input
78.750
16
--- expected
East
E

===
--- input
78.750
32
--- expected
East by north
EbN

===
--- input
90.000
4
--- expected
East
E

===
--- input
90.000
8
--- expected
East
E

===
--- input
90.000
16
--- expected
East
E

===
--- input
90.000
32
--- expected
East
E

===
--- input
101.250
4
--- expected
East
E

===
--- input
101.250
8
--- expected
East
E

===
--- input
101.250
16
--- expected
East-southeast
ESE

===
--- input
101.250
32
--- expected
East by south
EbS

===
--- input
112.500
4
--- expected
East
E

===
--- input
112.500
8
--- expected
Southeast
SE

===
--- input
112.500
16
--- expected
East-southeast
ESE

===
--- input
112.500
32
--- expected
East-southeast
ESE

===
--- input
123.750
4
--- expected
East
E

===
--- input
123.750
8
--- expected
Southeast
SE

===
--- input
123.750
16
--- expected
Southeast
SE

===
--- input
123.750
32
--- expected
Southeast by east
SEbE

===
--- input
135.000
4
--- expected
South
S

===
--- input
135.000
8
--- expected
Southeast
SE

===
--- input
135.000
16
--- expected
Southeast
SE

===
--- input
135.000
32
--- expected
Southeast
SE

===
--- input
146.250
4
--- expected
South
S

===
--- input
146.250
8
--- expected
Southeast
SE

===
--- input
146.250
16
--- expected
South-southeast
SSE

===
--- input
146.250
32
--- expected
Southeast by south
SEbS

===
--- input
157.500
4
--- expected
South
S

===
--- input
157.500
8
--- expected
South
S

===
--- input
157.500
16
--- expected
South-southeast
SSE

===
--- input
157.500
32
--- expected
South-southeast
SSE

===
--- input
168.750
4
--- expected
South
S

===
--- input
168.750
8
--- expected
South
S

===
--- input
168.750
16
--- expected
South
S

===
--- input
168.750
32
--- expected
South by east
SbE

===
--- input
180.000
4
--- expected
South
S

===
--- input
180.000
8
--- expected
South
S

===
--- input
180.000
16
--- expected
South
S

===
--- input
180.000
32
--- expected
South
S

===
--- input
191.250
4
--- expected
South
S

===
--- input
191.250
8
--- expected
South
S

===
--- input
191.250
16
--- expected
South-southwest
SSW

===
--- input
191.250
32
--- expected
South by west
SbW

===
--- input
202.500
4
--- expected
South
S

===
--- input
202.500
8
--- expected
Southwest
SW

===
--- input
202.500
16
--- expected
South-southwest
SSW

===
--- input
202.500
32
--- expected
South-southwest
SSW

===
--- input
213.750
4
--- expected
South
S

===
--- input
213.750
8
--- expected
Southwest
SW

===
--- input
213.750
16
--- expected
Southwest
SW

===
--- input
213.750
32
--- expected
Southwest by south
SWbS

===
--- input
225.000
4
--- expected
West
W

===
--- input
225.000
8
--- expected
Southwest
SW

===
--- input
225.000
16
--- expected
Southwest
SW

===
--- input
225.000
32
--- expected
Southwest
SW

===
--- input
236.250
4
--- expected
West
W

===
--- input
236.250
8
--- expected
Southwest
SW

===
--- input
236.250
16
--- expected
West-southwest
WSW

===
--- input
236.250
32
--- expected
Southwest by west
SWbW

===
--- input
247.500
4
--- expected
West
W

===
--- input
247.500
8
--- expected
West
W

===
--- input
247.500
16
--- expected
West-southwest
WSW

===
--- input
247.500
32
--- expected
West-southwest
WSW

===
--- input
258.750
4
--- expected
West
W

===
--- input
258.750
8
--- expected
West
W

===
--- input
258.750
16
--- expected
West
W

===
--- input
258.750
32
--- expected
West by south
WbS

===
--- input
270.000
4
--- expected
West
W

===
--- input
270.000
8
--- expected
West
W

===
--- input
270.000
16
--- expected
West
W

===
--- input
270.000
32
--- expected
West
W

===
--- input
281.250
4
--- expected
West
W

===
--- input
281.250
8
--- expected
West
W

===
--- input
281.250
16
--- expected
West-northwest
WNW

===
--- input
281.250
32
--- expected
West by north
WbN

===
--- input
292.500
4
--- expected
West
W

===
--- input
292.500
8
--- expected
Northwest
NW

===
--- input
292.500
16
--- expected
West-northwest
WNW

===
--- input
292.500
32
--- expected
West-northwest
WNW

===
--- input
303.750
4
--- expected
West
W

===
--- input
303.750
8
--- expected
Northwest
NW

===
--- input
303.750
16
--- expected
Northwest
NW

===
--- input
303.750
32
--- expected
Northwest by west
NWbW

===
--- input
315.000
4
--- expected
North
N

===
--- input
315.000
8
--- expected
Northwest
NW

===
--- input
315.000
16
--- expected
Northwest
NW

===
--- input
315.000
32
--- expected
Northwest
NW

===
--- input
326.250
4
--- expected
North
N

===
--- input
326.250
8
--- expected
Northwest
NW

===
--- input
326.250
16
--- expected
North-northwest
NNW

===
--- input
326.250
32
--- expected
Northwest by north
NWbN

===
--- input
337.500
4
--- expected
North
N

===
--- input
337.500
8
--- expected
North
N

===
--- input
337.500
16
--- expected
North-northwest
NNW

===
--- input
337.500
32
--- expected
North-northwest
NNW

===
--- input
348.750
4
--- expected
North
N

===
--- input
348.750
8
--- expected
North
N

===
--- input
348.750
16
--- expected
North
N

===
--- input
348.750
32
--- expected
North by west
NbW

===
--- input
360.000
4
--- expected
North
N

===
--- input
360.000
8
--- expected
North
N

===
--- input
360.000
16
--- expected
North
N

===
--- input
360.000
32
--- expected
North
N

