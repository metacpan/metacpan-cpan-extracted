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
    my ($str,$abbr) = split(/\n/,$block->input);
    my ($dir)       = split(/\n/,$block->expected);

    my $dobj        = Geo::Direction::Name->new;

    is sprintf("%.3f",$dobj->from_string($str)),  sprintf("%.3f",$dir);
    is sprintf("%.3f",$dobj->from_string($abbr)), sprintf("%.3f",$dir);
};

__END__
===
--- input
North
N
--- expected
0.000

===
--- input
North by east
NbE
--- expected
11.250

===
--- input
North-northeast
NNE
--- expected
22.500

===
--- input
Northeast by north
NEbN
--- expected
33.750

===
--- input
Northeast
NE
--- expected
45.000

===
--- input
Northeast by east
NEbE
--- expected
56.250

===
--- input
East-northeast
ENE
--- expected
67.500

===
--- input
East by north
EbN
--- expected
78.750

===
--- input
East
E
--- expected
90.000

===
--- input
East by south
EbS
--- expected
101.250

===
--- input
East-southeast
ESE
--- expected
112.500

===
--- input
Southeast by east
SEbE
--- expected
123.750

===
--- input
Southeast
SE
--- expected
135.000

===
--- input
Southeast by south
SEbS
--- expected
146.250

===
--- input
South-southeast
SSE
--- expected
157.500

===
--- input
South by east
SbE
--- expected
168.750

===
--- input
South
S
--- expected
180.000

===
--- input
South by west
SbW
--- expected
191.250

===
--- input
South-southwest
SSW
--- expected
202.500

===
--- input
Southwest by south
SWbS
--- expected
213.750

===
--- input
Southwest
SW
--- expected
225.000

===
--- input
Southwest by west
SWbW
--- expected
236.250

===
--- input
West-southwest
WSW
--- expected
247.500

===
--- input
West by south
WbS
--- expected
258.750

===
--- input
West
W
--- expected
270.000

===
--- input
West by north
WbN
--- expected
281.250

===
--- input
West-northwest
WNW
--- expected
292.500

===
--- input
Northwest by west
NWbW
--- expected
303.750

===
--- input
Northwest
NW
--- expected
315.000

===
--- input
Northwest by north
NWbN
--- expected
326.250

===
--- input
North-northwest
NNW
--- expected
337.500

===
--- input
North by west
NbW
--- expected
348.750

