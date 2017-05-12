use strict;
use Test::More 0.98;

use JSON5;
use JSON5::Parser;

my $parser = JSON5::Parser->new->allow_nonref;

is $parser->parse('null'),         undef, 'value: null';
is $parser->parse('true'),   JSON5::true, 'value: true';
is $parser->parse('false'), JSON5::false, 'value: false';
is $parser->parse('NaN'),        0+'NaN', 'value: NaN';
is $parser->parse('Infinity'),   0+'Inf', 'value: Infinity';
is $parser->parse('-Infinity'), 0+'-Inf', 'value: -Infinity';
is $parser->parse('-1'),              -1, 'value: -1';
is $parser->parse('0'),                0, 'value: 0';
is $parser->parse('1'),                1, 'value: 1';
is $parser->parse('-1.1'),          -1.1, 'value: -1.1';
is $parser->parse('0.1'),            0.1, 'value: 0.1';
is $parser->parse('1.1'),            1.1, 'value: 1.1';
is $parser->parse('-.1'),           -0.1, 'value: -.1';
is $parser->parse('.1'),             0.1, 'value: .1';
is $parser->parse('1e2'),            100, 'value: 1e2';
is $parser->parse('1.e-2'),         0.01, 'value: 1.e-2';
is $parser->parse('-.1e2'),          -10, 'value: -.1e2';
is $parser->parse('-1.0e-2'),      -0.01, 'value: -1.0e-2';
is $parser->parse('0x12AB'),        4779, 'value: 0x12AB';
is $parser->parse('0xcd34'),       52532, 'value: 0xcd34';
is $parser->parse(q!'str1'!),     'str1', 'value: str1';
is $parser->parse(q!"str2"!),     "str2", 'value: str2';
is_deeply $parser->parse('[]'),       [], 'value: []';
is_deeply $parser->parse('{}'),       {}, 'value: {}';

done_testing;

