######################################################################
#
# 0003-tests.t -- Built-in test (is / is not) tests
#
# Tests all 20 built-in tests: defined, none, string, number, sequence,
# mapping, iterable, callable, odd, even, divisibleby, upper, lower,
# equalto, ne, lt, le, gt, ge, in.
# Also tests: is not negation, compound conditions with tests.
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
sub nope{ r("{% if not ($_[0]) %}no{% endif %}",  $_[1]||{}) }

print "1..101\n";

###############################################################################
# defined / none
###############################################################################

# ok 1-6
is(yes('x is defined',   {x=>1}),    'yes', 'defined: integer');
is(yes('x is defined',   {x=>''}),   'yes', 'defined: empty string');
is(yes('x is defined',   {x=>0}),    'yes', 'defined: zero');
is(nope('x is defined',   {}),        'no',  'defined: undefined var is not defined');
is(yes('x is none',      {}),        'yes', 'none: undefined var is none');
is(nope('x is none',      {x=>1}),    'no',  'none: defined value is not none');

###############################################################################
# string / number
###############################################################################

# ok 7-14
is(yes('x is string',  {x=>'hello'}),  'yes', 'string: string value');
is(yes('x is string',  {x=>''}),       'yes', 'string: empty string');
is(yes('x is string',  {x=>'0'}),      'yes', 'string: "0" is a string');
is(nope('x is string',  {x=>[1,2]}),    'no',  'string: list is not a string');
is(yes('x is number',  {x=>42}),       'yes', 'number: integer');
is(yes('x is number',  {x=>3.14}),     'yes', 'number: float');
is(yes('x is number',  {x=>'-5'}),     'yes', 'number: numeric string');
is(nope('x is number',  {x=>'hello'}),  'no',  'number: non-numeric string');

###############################################################################
# sequence / mapping / iterable
###############################################################################

# ok 15-22
is(yes('x is sequence',  {x=>[1,2,3]}),        'yes', 'sequence: array ref');
is(nope('x is sequence',  {x=>'hello'}),         'no',  'sequence: string is not sequence');
is(nope('x is sequence',  {x=>{a=>1}}),          'no',  'sequence: hash is not sequence');
is(yes('x is mapping',   {x=>{a=>1}}),          'yes', 'mapping: hash ref');
is(nope('x is mapping',   {x=>[1,2]}),           'no',  'mapping: array is not mapping');
is(yes('x is iterable',  {x=>[1,2]}),           'yes', 'iterable: array');
is(yes('x is iterable',  {x=>{a=>1}}),          'yes', 'iterable: hash');
is(nope('x is iterable',  {x=>'hello'}),         'no',  'iterable: string is not iterable');

###############################################################################
# callable
###############################################################################

# ok 23-25
is(yes('x is callable',  {x=>sub{1}}),    'yes', 'callable: code ref');
is(nope('x is callable',  {x=>'func'}),    'no',  'callable: string is not callable');
is(nope('x is callable',  {}),             'no',  'callable: undef is not callable');

###############################################################################
# odd / even / divisibleby
###############################################################################

# ok 26-37
is(yes('x is odd',           {x=>1}),  'yes', 'odd: 1');
is(yes('x is odd',           {x=>3}),  'yes', 'odd: 3');
is(nope('x is odd',           {x=>2}),  'no',  'odd: 2 is not odd');
is(nope('x is odd',           {x=>0}),  'no',  'odd: 0 is not odd');
is(yes('x is even',          {x=>2}),  'yes', 'even: 2');
is(yes('x is even',          {x=>0}),  'yes', 'even: 0');
is(nope('x is even',          {x=>3}),  'no',  'even: 3 is not even');
is(yes('x is divisibleby 3', {x=>9}),  'yes', 'divisibleby: 9 by 3');
is(yes('x is divisibleby 5', {x=>10}), 'yes', 'divisibleby: 10 by 5');
is(nope('x is divisibleby 3', {x=>7}),  'no',  'divisibleby: 7 not by 3');
is(yes('x is divisibleby 1', {x=>7}),  'yes', 'divisibleby: any number by 1');
is(nope('x is divisibleby 2', {x=>7}),  'no',  'divisibleby: 7 not by 2');

###############################################################################
# upper / lower (test)
###############################################################################

# ok 38-43
is(yes('x is upper', {x=>'HELLO'}),   'yes', 'upper test: all caps');
is(nope('x is upper', {x=>'Hello'}),   'no',  'upper test: mixed case');
is(nope('x is upper', {x=>'hello'}),   'no',  'upper test: all lower');
is(yes('x is lower', {x=>'hello'}),   'yes', 'lower test: all lower');
is(nope('x is lower', {x=>'Hello'}),   'no',  'lower test: mixed case');
is(nope('x is lower', {x=>'HELLO'}),   'no',  'lower test: all caps');

###############################################################################
# equalto / ne
###############################################################################

# ok 44-51
is(yes('x is equalto 5',    {x=>5}),      'yes', 'equalto: integer match');
is(yes('x is equalto "hi"', {x=>'hi'}),   'yes', 'equalto: string match');
is(nope('x is equalto 5',    {x=>6}),      'no',  'equalto: no match');
is(nope('x is equalto "a"',  {x=>'b'}),    'no',  'equalto: string no match');
is(yes('x is ne 5',         {x=>6}),      'yes', 'ne: different value');
is(nope('x is ne 5',         {x=>5}),      'no',  'ne: same value');
is(yes('x is ne "a"',       {x=>'b'}),    'yes', 'ne: different string');
is(nope('x is ne "a"',       {x=>'a'}),    'no',  'ne: same string');

###############################################################################
# lt / le / gt / ge
###############################################################################

# ok 52-61
is(yes('x is lt 10', {x=>5}),   'yes', 'lt: 5 < 10');
is(nope('x is lt 5',  {x=>5}),   'no',  'lt: 5 not < 5');
is(nope('x is lt 3',  {x=>5}),   'no',  'lt: 5 not < 3');
is(yes('x is le 5',  {x=>5}),   'yes', 'le: 5 <= 5');
is(yes('x is le 6',  {x=>5}),   'yes', 'le: 5 <= 6');
is(nope('x is le 4',  {x=>5}),   'no',  'le: 5 not <= 4');
is(yes('x is gt 3',  {x=>5}),   'yes', 'gt: 5 > 3');
is(nope('x is gt 5',  {x=>5}),   'no',  'gt: 5 not > 5');
is(yes('x is ge 5',  {x=>5}),   'yes', 'ge: 5 >= 5');
is(nope('x is ge 6',  {x=>5}),   'no',  'ge: 5 not >= 6');

###############################################################################
# in (membership test)
###############################################################################

# ok 62-70
is(yes('"b" in x', {x=>['a','b','c']}), 'yes', 'in: element in list');
is(nope('"d" in x', {x=>['a','b','c']}), 'no',  'in: element not in list');
is(yes('"b" in x', {x=>{b=>1,c=>2}}),   'yes', 'in: key in hash');
is(nope('"d" in x', {x=>{b=>1,c=>2}}),   'no',  'in: key not in hash');
is(yes('"bc" in x', {x=>'abcde'}),      'yes', 'in: substring in string');
is(nope('"xy" in x', {x=>'abcde'}),      'no',  'in: substring not in string');
is(yes('2 in x',   {x=>[1,2,3]}),       'yes', 'in: integer in list');
is(nope('5 in x',   {x=>[1,2,3]}),       'no',  'in: integer not in list');
is(yes('"a" in x', {x=>'cat'}),         'yes', 'in: single char in string');

###############################################################################
# is not (negation)
###############################################################################

# ok 71-77
is(yes('x is not none',      {x=>1}),      'yes', 'is not none: defined value');
is(nope('x is not none',      {}),          'no',  'is not none: undefined is none');
is(yes('x is not defined',   {}),          'yes', 'is not defined: undefined var');
is(nope('x is not defined',   {x=>1}),      'no',  'is not defined: defined var');
is(yes('x is not sequence',  {x=>'str'}),  'yes', 'is not sequence: string');
is(yes('x is not odd',       {x=>4}),      'yes', 'is not odd: even number');
is(yes('x is not even',      {x=>3}),      'yes', 'is not even: odd number');

###############################################################################
# add_test custom test
###############################################################################

# ok 78-82
{
    my $t = HP::Handy->new(auto_escape=>0);
    $t->add_test('positive', sub { defined $_[0] && $_[0] > 0 });
    is($t->render_string('{% if x is positive %}yes{% endif %}', {x=>5}),
       'yes', 'custom test: positive true');
    is($t->render_string('{% if x is positive %}yes{% endif %}', {x=>-1}),
       '',    'custom test: positive false');
    is($t->render_string('{% if x is not positive %}no{% endif %}', {x=>-1}),
       'no',  'custom test: is not positive');
}
{
    my $t = HP::Handy->new(auto_escape=>0);
    $t->add_test('palindrome', sub {
        my $s = defined $_[0] ? "$_[0]" : ''; $s eq scalar reverse $s
    });
    is($t->render_string('{% if x is palindrome %}yes{% endif %}', {x=>'racecar'}),
       'yes', 'custom test: palindrome true');
    is($t->render_string('{% if x is palindrome %}yes{% endif %}', {x=>'hello'}),
       '',    'custom test: palindrome false');
}

###############################################################################
# Tests used inside for loop
###############################################################################

# ok 83-87
is(r('{% for n in x %}{% if n is odd %}{{ n }}{% endif %}{% endfor %}',
    {x=>[1,2,3,4,5]}), '135', 'test in for: filter odd numbers');
is(r('{% for n in x %}{% if n is even %}{{ n }}{% endif %}{% endfor %}',
    {x=>[1,2,3,4,5]}), '24', 'test in for: filter even numbers');
is(r('{% for n in x %}{% if n is divisibleby 3 %}{{ n }}{% endif %}{% endfor %}',
    {x=>[1,2,3,4,5,6,7,8,9]}), '369', 'test in for: divisibleby 3');
is(r('{% for s in x %}{% if s is upper %}{{ s }}{% endif %}{% endfor %}',
    {x=>['Hello','WORLD','foo']}), 'WORLD', 'test in for: upper strings');
is(r('{% for s in x %}{% if s is number %}{{ s }}{% endif %}{% endfor %}',
    {x=>['a','1','b','2']}), '12', 'test in for: numeric strings');

###############################################################################
# Tests combined with boolean logic
###############################################################################

# ok 88-94
is(yes('x is defined and x is number', {x=>5}),    'yes', 'and: defined and number');
is(nope('x is defined and x is number', {x=>'hi'}), 'no',  'and: defined but not number');
is(yes('x is none or y is defined', {y=>1}),        'yes', 'or: first false, second true');
is(yes('x is odd or x is even',     {x=>3}),        'yes', 'or: tautology with tests');
is(nope('x is odd and x is even',    {x=>3}),        'no',  'and: mutual exclusion');
is(yes('not (x is defined)',        {}),             'yes', 'not + test: not defined');
is(yes('x is defined and x > 0',   {x=>5}),         'yes', 'test and comparison');

###############################################################################
# is test with argument from variable
###############################################################################

# ok 95-98
is(yes('x is divisibleby y', {x=>12, y=>4}), 'yes', 'divisibleby: arg from var');
is(nope('x is divisibleby y', {x=>13, y=>4}), 'no',  'divisibleby: arg from var false');
is(yes('x is equalto y',     {x=>5, y=>5}),  'yes', 'equalto: arg from var');
is(nope('x is equalto y',     {x=>5, y=>6}),  'no',  'equalto: arg from var no match');

###############################################################################
# Inline conditional with test
###############################################################################

# ok 99-101
is(r('{{ "odd" if x is odd else "even" }}',       {x=>7}), 'odd',  'inline if with test: odd');
is(r('{{ "odd" if x is odd else "even" }}',       {x=>4}), 'even', 'inline if with test: even');
is(r('{{ x if x is defined else "default" }}',    {x=>'v'}), 'v', 'inline if with defined test');

END { print "# $PASS passed, $FAIL failed\n"; exit($FAIL ? 1 : 0) }
