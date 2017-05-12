use strict;
use Test::Base;
plan tests => 1 * blocks;

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

    my $dobj        = Geo::Direction::Name->new("ko_KR");

    is sprintf("%.3f",$dobj->from_string($str)),  sprintf("%.3f",$dir);
};

__END__
===
--- input
북
--- expected
0.000

===
--- input
북미동
--- expected
11.250

===
--- input
북북동
--- expected
22.500

===
--- input
북동미북
--- expected
33.750

===
--- input
북동
--- expected
45.000

===
--- input
북동미동
--- expected
56.250

===
--- input
동북동
--- expected
67.500

===
--- input
동미북
--- expected
78.750

===
--- input
동
--- expected
90.000

===
--- input
동미남
--- expected
101.250

===
--- input
동남동
--- expected
112.500

===
--- input
남동미동
--- expected
123.750

===
--- input
남동
--- expected
135.000

===
--- input
남동미남
--- expected
146.250

===
--- input
남남동
--- expected
157.500

===
--- input
남미동
--- expected
168.750

===
--- input
남
--- expected
180.000

===
--- input
남미서
--- expected
191.250

===
--- input
남남서
--- expected
202.500

===
--- input
남서미남
--- expected
213.750

===
--- input
남서
--- expected
225.000

===
--- input
남서미서
--- expected
236.250

===
--- input
서남서
--- expected
247.500

===
--- input
서미남
--- expected
258.750

===
--- input
서
--- expected
270.000

===
--- input
서미북
--- expected
281.250

===
--- input
서북서
--- expected
292.500

===
--- input
북서미서
--- expected
303.750

===
--- input
북서
--- expected
315.000

===
--- input
북서미북
--- expected
326.250

===
--- input
북북서
--- expected
337.500

===
--- input
북미서
--- expected
348.750

