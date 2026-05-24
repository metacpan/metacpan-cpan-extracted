######################################################################
#
# 0007-expressions.t -- Expression engine tests
#
# Tests: arithmetic, string concat, comparison, boolean logic,
# ternary, in/not in, range, attribute access, type literals,
# operator precedence, edge cases.
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use HP::Handy;

my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my($c,$n)=@_; $T++; $c?($PASS++,print "ok $T - $n\n"):($FAIL++,print "not ok $T - $n\n") }
sub is { my($g,$e,$n)=@_; $T++;
    defined($g) && "$g" eq "$e"
        ? ($PASS++, print "ok $T - $n\n")
        : ($FAIL++, print "not ok $T - $n  (got='".( defined $g?$g:'undef')."', exp='$e')\n") }

sub r { HP::Handy->new(auto_escape=>0)->render_string($_[0], $_[1]||{}) }
sub yes { r("{% if $_[0] %}yes{% endif %}", $_[1]||{}) }

print "1..89\n";

###############################################################################
# Arithmetic operators
###############################################################################

# ok 1-14
is(r('{{ 1 + 2 }}'),      '3',   'add: 1+2');
is(r('{{ 10 - 3 }}'),     '7',   'sub: 10-3');
is(r('{{ 3 * 4 }}'),      '12',  'mul: 3*4');
is(r('{{ 10 / 4 }}'),     '2.5', 'div: 10/4');
is(r('{{ 10 // 3 }}'),    '3',   'idiv: 10//3');
is(r('{{ 10 % 3 }}'),     '1',   'mod: 10%3');
is(r('{{ 2 ** 8 }}'),     '256', 'pow: 2**8');
is(r('{{ -5 + 3 }}'),     '-2',  'neg+pos');
is(r('{{ 0 + 0 }}'),      '0',   'zero+zero');
is(r('{{ x + 1 }}', {x=>5}),  '6',  'var + literal');
is(r('{{ x - y }}', {x=>10, y=>3}), '7', 'var - var');
is(r('{{ x * y }}', {x=>3, y=>4}),  '12','var * var');
is(r('{{ 7 // 2 }}'),     '3',   'idiv rounds toward zero');
is(r('{{ -7 // 2 }}'),    '-3',  'idiv negative (Perl floor division)');

###############################################################################
# String concatenation ~
###############################################################################

# ok 15-22
is(r('{{ "hello" ~ " " ~ "world" }}'),      'hello world', 'concat: three strings');
is(r('{{ x ~ "!" }}', {x=>'hi'}),           'hi!',         'concat: var+literal');
is(r('{{ x ~ y }}', {x=>'ab', y=>'cd'}),    'abcd',        'concat: var+var');
is(r('{{ "" ~ "a" }}'),                      'a',           'concat: empty+str');
is(r('{{ x ~ "" }}', {x=>'hi'}),            'hi',          'concat: str+empty');
is(r('{{ 1 ~ 2 }}'),                         '12',          'concat: numbers become strings');
is(r('{{ x ~ x }}', {x=>'ab'}),             'abab',        'concat: self concat');
is(r('{{ "a" ~ "b" ~ "c" }}'),              'abc',         'concat: chained');

###############################################################################
# Comparison operators -- numeric
###############################################################################

# ok 23-36
is(yes('5 == 5'),   'yes', '==: equal');
is(yes('5 == 6'),   '',    '==: not equal');
is(yes('5 != 6'),   'yes', '!=: not equal');
is(yes('5 != 5'),   '',    '!=: equal');
is(yes('5 > 3'),    'yes', '>: greater');
is(yes('3 > 5'),    '',    '>: not greater');
is(yes('5 >= 5'),   'yes', '>=: equal');
is(yes('5 >= 6'),   '',    '>=: less');
is(yes('3 < 5'),    'yes', '<: less');
is(yes('5 < 3'),    '',    '<: not less');
is(yes('5 <= 5'),   'yes', '<=: equal');
is(yes('6 <= 5'),   '',    '<=: greater');
is(yes('0 == 0'),   'yes', '==: zero');
is(yes('-1 < 0'),   'yes', '<: negative');

###############################################################################
# Comparison operators -- string
###############################################################################

# ok 37-42
is(yes('"abc" == "abc"'), 'yes', 'str ==: equal');
is(yes('"abc" == "def"'), '',    'str ==: not equal');
is(yes('"abc" != "def"'), 'yes', 'str !=: not equal');
is(yes('"abc" != "abc"'), '',    'str !=: equal');
is(yes('x == "hi"', {x=>'hi'}), 'yes', 'str ==: var comparison');
is(yes('x != "hi"', {x=>'bye'}), 'yes', 'str !=: var comparison');

###############################################################################
# Boolean operators
###############################################################################

# ok 43-54
is(yes('1 and 1'),   'yes', 'and: both true');
is(yes('1 and 0'),   '',    'and: second false');
is(yes('0 and 1'),   '',    'and: first false');
is(yes('0 or 1'),    'yes', 'or: second true');
is(yes('1 or 0'),    'yes', 'or: first true');
is(yes('0 or 0'),    '',    'or: both false');
is(yes('not 0'),     'yes', 'not: falsy');
is(yes('not 1'),     '',    'not: truthy');
is(yes('not not 1'), 'yes', 'not not: double negation');
is(r('{{ 1 and "a" }}'),     'a',  'and: returns last truthy');
is(r('{{ 0 or "b" }}'),      'b',  'or: returns first truthy');
is(r('{{ 0 and "a" }}'),     '0',  'and: returns first falsy');

###############################################################################
# Ternary (inline conditional)
###############################################################################

# ok 55-62
is(r('{{ "y" if 1 else "n" }}'),         'y',  'ternary: true');
is(r('{{ "y" if 0 else "n" }}'),         'n',  'ternary: false');
is(r('{{ x if x else "none" }}', {x=>5}),'5',  'ternary: var value');
is(r('{{ x if x else "none" }}', {}),    'none','ternary: undefined');
is(r('{{ a+b if a>0 else 0 }}', {a=>3, b=>4}), '7',   'ternary: expr branches');
is(r('{{ x if x > 0 else -x }}', {x=>-5}),     '5',   'ternary: absolute value');
is(r('{{ "big" if x >= 100 else "small" }}', {x=>100}), 'big',   'ternary: >= in cond');
is(r('{{ "big" if x >= 100 else "small" }}', {x=>99}),  'small', 'ternary: >= false');

###############################################################################
# in / not in
###############################################################################

# ok 63-72
is(yes('"b" in x', {x=>['a','b','c']}), 'yes', 'in: list');
is(yes('"d" in x', {x=>['a','b','c']}), '',    'in: not in list');
is(yes('2 in x',   {x=>[1,2,3]}),       'yes', 'in: integer list');
is(yes('"b" in x', {x=>{b=>1}}),        'yes', 'in: hash key');
is(yes('"z" in x', {x=>{b=>1}}),        '',    'in: hash key missing');
is(yes('"bc" in x',{x=>'abcde'}),       'yes', 'in: substring');
is(yes('"xy" in x',{x=>'abcde'}),       '',    'in: substring missing');
is(yes('"d" not in x', {x=>['a','b']}), 'yes', 'not in: missing from list');
is(yes('"a" not in x', {x=>['a','b']}), '',    'not in: present in list');
is(yes('"xy" not in x',{x=>'abcde'}),   'yes', 'not in: substring missing');

###############################################################################
# range()
###############################################################################

# ok 73-78
is(r('{{ range(3)|join(",") }}'),           '0,1,2', 'range(3)');
is(r('{{ range(1,4)|join(",") }}'),         '1,2,3', 'range(1,4)');
is(r('{{ range(0,10,3)|join(",") }}'),      '0,3,6,9','range step');
is(r('{{ range(5,0,-1)|join(",") }}'),      '5,4,3,2,1','range negative step');
is(r('{{ range(0)|join(",") }}'),           '',      'range(0) empty');
is(r('{{ range(x)|join(",") }}', {x=>3}),  '0,1,2', 'range(var)');

###############################################################################
# Attribute and index access
###############################################################################

# ok 79-86
is(r('{{ x.a }}',      {x=>{a=>1}}),   '1',   'dot hash');
is(r('{{ x["a"] }}',   {x=>{a=>1}}),   '1',   'bracket hash');
is(r("{{ x['a'] }}", {x=>{a=>1}}),     '1',   'single-quote bracket hash');
is(r('{{ x[0] }}',     {x=>[5,6,7]}),  '5',   'array index 0');
is(r('{{ x[-1] }}',    {x=>[5,6,7]}),  '7',   'array negative index');
is(r('{{ x[0:2]|join(",") }}', {x=>['a','b','c','d']}), 'a,b', 'slice [0:2]');
is(r('{{ x[1:-1]|join(",") }}',{x=>['a','b','c','d']}), 'b,c', 'slice [1:-1]');
is(r('{{ x.b.c }}',    {x=>{b=>{c=>'deep'}}}), 'deep', 'chained dot');

###############################################################################
# Operator precedence
###############################################################################

# ok 87-89
is(r('{{ 2 + 3 * 4 }}'),   '14', 'precedence: no parens (left to right -- limitation)');
is(r('{{ (2 + 3) * 4 }}'), '20', 'precedence: parens (2+3)*4=20');
is(r('{{ 2 * (3 + 4) }}'), '14', 'precedence: parens 2*(3+4)=14');

END { print "# $PASS passed, $FAIL failed\n"; exit($FAIL ? 1 : 0) }
