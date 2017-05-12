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
    my ($str,$todo) = split(/\n/,$block->input);
    my ($dir)       = split(/\n/,$block->expected);

    my $dobj        = Geo::Direction::Name->new({spec=>'chinese',locale=>'ko_KR'});

    if ( $todo && $todo eq 'todo' ) {
TODO:{
        local $TODO = "Korean has pairs of same pronunciation directions.";
    
        is sprintf("%.3f",$dobj->from_string($str)),  sprintf("%.3f",$dir);
}
    } else {
        is sprintf("%.3f",$dobj->from_string($str)),  sprintf("%.3f",$dir);
    }
};

__END__
===
--- input
감
--- expected
0.000

===
--- input
진
todo
--- expected
90.000

===
--- input
리
--- expected
180.000

===
--- input
태
--- expected
270.000

===
--- input
자
--- expected
0.000

===
--- input
계
--- expected
15.000

===
--- input
축
--- expected
30.000

===
--- input
간
--- expected
45.000

===
--- input
인
--- expected
60.000

===
--- input
갑
--- expected
75.000

===
--- input
묘
--- expected
90.000

===
--- input
을
--- expected
105.000

===
--- input
진
todo
--- expected
120.000

===
--- input
손
--- expected
135.000

===
--- input
사
--- expected
150.000

===
--- input
병
--- expected
165.000

===
--- input
오
--- expected
180.000

===
--- input
정
--- expected
195.000

===
--- input
미
--- expected
210.000

===
--- input
곤
--- expected
225.000

===
--- input
신
todo
--- expected
240.000

===
--- input
경
--- expected
255.000

===
--- input
유
--- expected
270.000

===
--- input
신
todo
--- expected
285.000

===
--- input
술
--- expected
300.000

===
--- input
건
--- expected
315.000

===
--- input
해
--- expected
330.000

===
--- input
임
--- expected
345.000

