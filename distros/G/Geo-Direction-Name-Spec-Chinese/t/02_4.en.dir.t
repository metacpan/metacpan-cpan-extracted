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

    my $dobj        = Geo::Direction::Name->new({spec=>'chinese',locale=>'en_US'});

    is sprintf("%.3f",$dobj->from_string($str)),  sprintf("%.3f",$dir);
};

__END__
===
--- input
kan
--- expected
0.000

===
--- input
zhen
--- expected
90.000

===
--- input
li
--- expected
180.000

===
--- input
dui
--- expected
270.000

===
--- input
zi
--- expected
0.000

===
--- input
gui
--- expected
15.000

===
--- input
chou
--- expected
30.000

===
--- input
gen
--- expected
45.000

===
--- input
yin
--- expected
60.000

===
--- input
jia
--- expected
75.000

===
--- input
mao
--- expected
90.000

===
--- input
yi
--- expected
105.000

===
--- input
chen
--- expected
120.000

===
--- input
xun
--- expected
135.000

===
--- input
si
--- expected
150.000

===
--- input
bing
--- expected
165.000

===
--- input
wu
--- expected
180.000

===
--- input
ding
--- expected
195.000

===
--- input
wei
--- expected
210.000

===
--- input
kun
--- expected
225.000

===
--- input
shen
--- expected
240.000

===
--- input
geng
--- expected
255.000

===
--- input
you
--- expected
270.000

===
--- input
xin
--- expected
285.000

===
--- input
xu
--- expected
300.000

===
--- input
qian
--- expected
315.000

===
--- input
hai
--- expected
330.000

===
--- input
ren
--- expected
345.000
