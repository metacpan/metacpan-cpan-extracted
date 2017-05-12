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

    my $dobj        = Geo::Direction::Name->new({spec=>'chinese',locale=>'ko_KR'});

    is $dobj->to_string($dir,{ devide => $dev, abbreviation => 0 }) ,$str;
    is $dobj->to_string($dir,{ devide => $dev, abbreviation => 1 }) ,$str;
};

__END__
===
--- input
0.000
8
--- expected
감

===
--- input
0.000
12
--- expected
자

===
--- input
0.000
24
--- expected
자

===
--- input
15
8
--- expected
감

===
--- input
15
12
--- expected
축

===
--- input
15
24
--- expected
계

===
--- input
30
8
--- expected
간

===
--- input
30
12
--- expected
축

===
--- input
30
24
--- expected
축

===
--- input
45
8
--- expected
간

===
--- input
45
12
--- expected
인

===
--- input
45
24
--- expected
간

===
--- input
60
8
--- expected
간

===
--- input
60
12
--- expected
인

===
--- input
60
24
--- expected
인

===
--- input
75
8
--- expected
진

===
--- input
75
12
--- expected
묘

===
--- input
75
24
--- expected
갑

===
--- input
90
8
--- expected
진

===
--- input
90
12
--- expected
묘

===
--- input
90
24
--- expected
묘

===
--- input
105
8
--- expected
진

===
--- input
105
12
--- expected
진

===
--- input
105
24
--- expected
을

===
--- input
120
8
--- expected
손

===
--- input
120
12
--- expected
진

===
--- input
120
24
--- expected
진

===
--- input
135
8
--- expected
손

===
--- input
135
12
--- expected
사

===
--- input
135
24
--- expected
손

===
--- input
150
8
--- expected
손

===
--- input
150
12
--- expected
사

===
--- input
150
24
--- expected
사

===
--- input
165
8
--- expected
리

===
--- input
165
12
--- expected
오

===
--- input
165
24
--- expected
병

===
--- input
180
8
--- expected
리

===
--- input
180
12
--- expected
오

===
--- input
180
24
--- expected
오

===
--- input
195
8
--- expected
리

===
--- input
195
12
--- expected
미

===
--- input
195
24
--- expected
정

===
--- input
210
8
--- expected
곤

===
--- input
210
12
--- expected
미

===
--- input
210
24
--- expected
미

===
--- input
225
8
--- expected
곤

===
--- input
225
12
--- expected
신

===
--- input
225
24
--- expected
곤

===
--- input
240
8
--- expected
곤

===
--- input
240
12
--- expected
신

===
--- input
240
24
--- expected
신

===
--- input
255
8
--- expected
태

===
--- input
255
12
--- expected
유

===
--- input
255
24
--- expected
경

===
--- input
270
8
--- expected
태

===
--- input
270
12
--- expected
유

===
--- input
270
24
--- expected
유

===
--- input
285
8
--- expected
태

===
--- input
285
12
--- expected
술

===
--- input
285
24
--- expected
신

===
--- input
300
8
--- expected
건

===
--- input
300
12
--- expected
술

===
--- input
300
24
--- expected
술

===
--- input
315
8
--- expected
건

===
--- input
315
12
--- expected
해

===
--- input
315
24
--- expected
건

===
--- input
330
8
--- expected
건

===
--- input
330
12
--- expected
해

===
--- input
330
24
--- expected
해

===
--- input
345
8
--- expected
감

===
--- input
345
12
--- expected
자

===
--- input
345
24
--- expected
임

===
--- input
360
8
--- expected
감

===
--- input
360
12
--- expected
자

===
--- input
360
24
--- expected
자
