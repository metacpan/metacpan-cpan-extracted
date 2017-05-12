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

    my $dobj        = Geo::Direction::Name->new({spec=>'chinese',locale=>'en_US'});

    is $dobj->to_string($dir,{ devide => $dev, abbreviation => 0 }) ,$str;
    is $dobj->to_string($dir,{ devide => $dev, abbreviation => 1 }) ,$str;
};

__END__
===
--- input
0.000
8
--- expected
kan

===
--- input
0.000
12
--- expected
zi

===
--- input
0.000
24
--- expected
zi

===
--- input
15
8
--- expected
kan

===
--- input
15
12
--- expected
chou

===
--- input
15
24
--- expected
gui

===
--- input
30
8
--- expected
gen

===
--- input
30
12
--- expected
chou

===
--- input
30
24
--- expected
chou

===
--- input
45
8
--- expected
gen

===
--- input
45
12
--- expected
yin

===
--- input
45
24
--- expected
gen

===
--- input
60
8
--- expected
gen

===
--- input
60
12
--- expected
yin

===
--- input
60
24
--- expected
yin

===
--- input
75
8
--- expected
zhen

===
--- input
75
12
--- expected
mao

===
--- input
75
24
--- expected
jia

===
--- input
90
8
--- expected
zhen

===
--- input
90
12
--- expected
mao

===
--- input
90
24
--- expected
mao

===
--- input
105
8
--- expected
zhen

===
--- input
105
12
--- expected
chen

===
--- input
105
24
--- expected
yi

===
--- input
120
8
--- expected
xun

===
--- input
120
12
--- expected
chen

===
--- input
120
24
--- expected
chen

===
--- input
135
8
--- expected
xun

===
--- input
135
12
--- expected
si

===
--- input
135
24
--- expected
xun

===
--- input
150
8
--- expected
xun

===
--- input
150
12
--- expected
si

===
--- input
150
24
--- expected
si

===
--- input
165
8
--- expected
li

===
--- input
165
12
--- expected
wu

===
--- input
165
24
--- expected
bing

===
--- input
180
8
--- expected
li

===
--- input
180
12
--- expected
wu

===
--- input
180
24
--- expected
wu

===
--- input
195
8
--- expected
li

===
--- input
195
12
--- expected
wei

===
--- input
195
24
--- expected
ding

===
--- input
210
8
--- expected
kun

===
--- input
210
12
--- expected
wei

===
--- input
210
24
--- expected
wei

===
--- input
225
8
--- expected
kun

===
--- input
225
12
--- expected
shen

===
--- input
225
24
--- expected
kun

===
--- input
240
8
--- expected
kun

===
--- input
240
12
--- expected
shen

===
--- input
240
24
--- expected
shen

===
--- input
255
8
--- expected
dui

===
--- input
255
12
--- expected
you

===
--- input
255
24
--- expected
geng

===
--- input
270
8
--- expected
dui

===
--- input
270
12
--- expected
you

===
--- input
270
24
--- expected
you

===
--- input
285
8
--- expected
dui

===
--- input
285
12
--- expected
xu

===
--- input
285
24
--- expected
xin

===
--- input
300
8
--- expected
qian

===
--- input
300
12
--- expected
xu

===
--- input
300
24
--- expected
xu

===
--- input
315
8
--- expected
qian

===
--- input
315
12
--- expected
hai

===
--- input
315
24
--- expected
qian

===
--- input
330
8
--- expected
qian

===
--- input
330
12
--- expected
hai

===
--- input
330
24
--- expected
hai

===
--- input
345
8
--- expected
kan

===
--- input
345
12
--- expected
zi

===
--- input
345
24
--- expected
ren

===
--- input
360
8
--- expected
kan

===
--- input
360
12
--- expected
zi

===
--- input
360
24
--- expected
zi

