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

    my $dobj        = Geo::Direction::Name->new({spec=>'chinese'});

    is sprintf("%.3f",$dobj->from_string($str)),  sprintf("%.3f",$dir);
};

__END__
===
--- input
坎
--- expected
0.000

===
--- input
震
--- expected
90.000

===
--- input
离
--- expected
180.000

===
--- input
兑
--- expected
270.000

===
--- input
子
--- expected
0.000

===
--- input
癸
--- expected
15.000

===
--- input
丑
--- expected
30.000

===
--- input
艮
--- expected
45.000

===
--- input
寅
--- expected
60.000

===
--- input
甲
--- expected
75.000

===
--- input
卯
--- expected
90.000

===
--- input
乙
--- expected
105.000

===
--- input
辰
--- expected
120.000

===
--- input
巽
--- expected
135.000

===
--- input
巳
--- expected
150.000

===
--- input
丙
--- expected
165.000

===
--- input
午
--- expected
180.000

===
--- input
丁
--- expected
195.000

===
--- input
未
--- expected
210.000

===
--- input
坤
--- expected
225.000

===
--- input
申
--- expected
240.000

===
--- input
庚
--- expected
255.000

===
--- input
酉
--- expected
270.000

===
--- input
辛
--- expected
285.000

===
--- input
戌
--- expected
300.000

===
--- input
乾
--- expected
315.000

===
--- input
亥
--- expected
330.000

===
--- input
壬
--- expected
345.000

