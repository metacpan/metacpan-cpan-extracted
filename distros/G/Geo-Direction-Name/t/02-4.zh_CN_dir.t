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

    my $dobj        = Geo::Direction::Name->new("zh_CN");

    is sprintf("%.3f",$dobj->from_string($str)),  sprintf("%.3f",$dir);
};

__END__
===
--- input
北
--- expected
0.000

===
--- input
北微东
--- expected
11.250

===
--- input
东北偏北
--- expected
22.500

===
--- input
东北微北
--- expected
33.750

===
--- input
东北
--- expected
45.000

===
--- input
东北微东
--- expected
56.250

===
--- input
东北偏东
--- expected
67.500

===
--- input
东微北
--- expected
78.750

===
--- input
东
--- expected
90.000

===
--- input
东微南
--- expected
101.250

===
--- input
东南偏东
--- expected
112.500

===
--- input
东南微东
--- expected
123.750

===
--- input
东南
--- expected
135.000

===
--- input
东南微南
--- expected
146.250

===
--- input
东南偏南
--- expected
157.500

===
--- input
南微东
--- expected
168.750

===
--- input
南
--- expected
180.000

===
--- input
南微西
--- expected
191.250

===
--- input
西南偏南
--- expected
202.500

===
--- input
西南微南
--- expected
213.750

===
--- input
西南
--- expected
225.000

===
--- input
西南微西
--- expected
236.250

===
--- input
西南偏西
--- expected
247.500

===
--- input
西微南
--- expected
258.750

===
--- input
西
--- expected
270.000

===
--- input
西微北
--- expected
281.250

===
--- input
西北偏西
--- expected
292.500

===
--- input
西北微西
--- expected
303.750

===
--- input
西北
--- expected
315.000

===
--- input
西北微北
--- expected
326.250

===
--- input
西北偏北
--- expected
337.500

===
--- input
北微西
--- expected
348.750

