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

    my $dobj        = Geo::Direction::Name->new({spec=>'chinese',locale=>'zh_TW'});

    is $dobj->to_string($dir,{ devide => $dev, abbreviation => 0 }) ,$str;
    is $dobj->to_string($dir,{ devide => $dev, abbreviation => 1 }) ,$str;
};

__END__
===
--- input
0.000
8
--- expected
坎

===
--- input
0.000
12
--- expected
子

===
--- input
0.000
24
--- expected
子

===
--- input
15
8
--- expected
坎

===
--- input
15
12
--- expected
丑

===
--- input
15
24
--- expected
癸

===
--- input
30
8
--- expected
艮

===
--- input
30
12
--- expected
丑

===
--- input
30
24
--- expected
丑

===
--- input
45
8
--- expected
艮

===
--- input
45
12
--- expected
寅

===
--- input
45
24
--- expected
艮

===
--- input
60
8
--- expected
艮

===
--- input
60
12
--- expected
寅

===
--- input
60
24
--- expected
寅

===
--- input
75
8
--- expected
震

===
--- input
75
12
--- expected
卯

===
--- input
75
24
--- expected
甲

===
--- input
90
8
--- expected
震

===
--- input
90
12
--- expected
卯

===
--- input
90
24
--- expected
卯

===
--- input
105
8
--- expected
震

===
--- input
105
12
--- expected
辰

===
--- input
105
24
--- expected
乙

===
--- input
120
8
--- expected
巽

===
--- input
120
12
--- expected
辰

===
--- input
120
24
--- expected
辰

===
--- input
135
8
--- expected
巽

===
--- input
135
12
--- expected
巳

===
--- input
135
24
--- expected
巽

===
--- input
150
8
--- expected
巽

===
--- input
150
12
--- expected
巳

===
--- input
150
24
--- expected
巳

===
--- input
165
8
--- expected
離

===
--- input
165
12
--- expected
午

===
--- input
165
24
--- expected
丙

===
--- input
180
8
--- expected
離

===
--- input
180
12
--- expected
午

===
--- input
180
24
--- expected
午

===
--- input
195
8
--- expected
離

===
--- input
195
12
--- expected
未

===
--- input
195
24
--- expected
丁

===
--- input
210
8
--- expected
坤

===
--- input
210
12
--- expected
未

===
--- input
210
24
--- expected
未

===
--- input
225
8
--- expected
坤

===
--- input
225
12
--- expected
申

===
--- input
225
24
--- expected
坤

===
--- input
240
8
--- expected
坤

===
--- input
240
12
--- expected
申

===
--- input
240
24
--- expected
申

===
--- input
255
8
--- expected
兌

===
--- input
255
12
--- expected
酉

===
--- input
255
24
--- expected
庚

===
--- input
270
8
--- expected
兌

===
--- input
270
12
--- expected
酉

===
--- input
270
24
--- expected
酉

===
--- input
285
8
--- expected
兌

===
--- input
285
12
--- expected
戌

===
--- input
285
24
--- expected
辛

===
--- input
300
8
--- expected
乾

===
--- input
300
12
--- expected
戌

===
--- input
300
24
--- expected
戌

===
--- input
315
8
--- expected
乾

===
--- input
315
12
--- expected
亥

===
--- input
315
24
--- expected
乾

===
--- input
330
8
--- expected
乾

===
--- input
330
12
--- expected
亥

===
--- input
330
24
--- expected
亥

===
--- input
345
8
--- expected
坎

===
--- input
345
12
--- expected
子

===
--- input
345
24
--- expected
壬

===
--- input
360
8
--- expected
坎

===
--- input
360
12
--- expected
子

===
--- input
360
24
--- expected
子
