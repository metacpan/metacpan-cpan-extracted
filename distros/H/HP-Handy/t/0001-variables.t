######################################################################
#
# 0001-variables.t -- Variable expansion tests
#
# Tests {{ expr }} output for all access patterns:
#   simple vars, hash/array access, chaining, undefined, None/True/False,
#   string literals, integer/float literals, list/dict literals.
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

print "1..56\n";

###############################################################################
# Simple variable
###############################################################################

# ok 1
is(r('{{ x }}', {x=>'hello'}), 'hello', 'simple string var');
# ok 2
is(r('{{ x }}', {x=>42}),      '42',    'simple integer var');
# ok 3
is(r('{{ x }}', {x=>3.14}),    '3.14',  'simple float var');
# ok 4
is(r('{{ x }}', {}),           '',      'undefined var renders empty string');
# ok 5
is(r('{{ x }}', {x=>0}),       '0',     'zero value renders as 0');
# ok 6
is(r('{{ x }}', {x=>''}),      '',      'empty string var');

###############################################################################
# Literal values
###############################################################################

# ok 7
is(r('"hello"'),  '"hello"',  'bare string literal outside tags is plain text passthrough');
# ok 8
is(r('{{ "hello" }}'), 'hello', 'string literal double-quote');
# ok 9
is(r("{{ 'world' }}"), 'world', 'string literal single-quote');
# ok 10
is(r('{{ 42 }}'),      '42',    'integer literal');
# ok 11
is(r('{{ 3.14 }}'),    '3.14',  'float literal');
# ok 12
is(r('{{ true }}'),    '1',     'true literal');
# ok 13
is(r('{{ false }}'),   '0',     'false literal (renders as 0)');
# ok 14
is(r('{{ none }}'),    '',      'none literal renders empty');
# ok 15
is(r('{{ None }}'),    '',      'None literal (capital) renders empty');

###############################################################################
# Hash attribute access
###############################################################################

# ok 16
is(r('{{ u.name }}', {u=>{name=>'ina'}}),      'ina',  'hash dot access');
# ok 17
is(r('{{ u.age }}',  {u=>{age=>30}}),          '30',   'hash dot access integer');
# ok 18
is(r('{{ u.missing }}', {u=>{name=>'ina'}}),   '',     'hash dot access missing key');
# ok 19
is(r('{{ u["name"] }}', {u=>{name=>'ina'}}),   'ina',  'hash bracket string key');
# ok 20
is(r("{{ u['name'] }}", {u=>{name=>'ina'}}),   'ina',  'hash bracket single-quote key');

###############################################################################
# Array index access
###############################################################################

# ok 21
is(r('{{ a[0] }}', {a=>['x','y','z']}),   'x',  'array index 0');
# ok 22
is(r('{{ a[1] }}', {a=>['x','y','z']}),   'y',  'array index 1');
# ok 23
is(r('{{ a[2] }}', {a=>['x','y','z']}),   'z',  'array index 2');
# ok 24
is(r('{{ a[-1] }}', {a=>['x','y','z']}),  'z',  'array negative index -1');
# ok 25
is(r('{{ a[-2] }}', {a=>['x','y','z']}),  'y',  'array negative index -2');

###############################################################################
# Chained access
###############################################################################

# ok 26
is(r('{{ a.b.c }}', {a=>{b=>{c=>'deep'}}}),     'deep',  'chained hash access 3 levels');
# ok 27
is(r('{{ users[0].name }}', {users=>[{name=>'Alice'},{name=>'Bob'}]}),
   'Alice', 'array index then hash dot');
# ok 28
is(r('{{ users[1].name }}', {users=>[{name=>'Alice'},{name=>'Bob'}]}),
   'Bob',   'array index 1 then hash dot');

###############################################################################
# Slice
###############################################################################

# ok 29
is(r('{{ a[0:2]|join(",") }}', {a=>['x','y','z']}), 'x,y', 'slice [0:2]');
# ok 30
is(r('{{ a[1:]|join(",") }}',  {a=>['x','y','z']}), 'y,z', 'slice [1:]');
# ok 31
is(r('{{ a[:2]|join(",") }}',  {a=>['x','y','z']}), 'x,y', 'slice [:2]');

###############################################################################
# Multiple variables in one template
###############################################################################

# ok 32
is(r('{{ a }} {{ b }}', {a=>'Hello', b=>'World'}), 'Hello World', 'two vars with space');
# ok 33
is(r('{{ a }}{{ b }}{{ a }}', {a=>'x', b=>'y'}),   'xyx',         'vars concatenated');

###############################################################################
# Special characters in string literals
###############################################################################

# ok 34
is(r('{{ "line1\nline2" }}'), "line1\nline2", 'string literal with \n escape');
# ok 35
is(r('{{ "tab\there" }}'),   "tab\there",    'string literal with \t escape');
# ok 36
is(r('{{ "it\'s" }}'),       "it's",         'single-quote escaped in double-quoted string');

###############################################################################
# List literal
###############################################################################

# ok 37
is(r('{{ [1,2,3]|join(",") }}'), '1,2,3', 'list literal inline');
# ok 38
is(r('{{ ["a","b"]|first }}'),   'a',     'list literal first');

###############################################################################
# Dict literal
###############################################################################

# ok 39
is(r('{{ {"k":"v"}["k"] }}'), 'v', 'dict literal access by key');

###############################################################################
# Variable with whitespace control
###############################################################################

# ok 40
is(r("  {{- x -}}  ", {x=>'hi'}), 'hi', 'var whitespace control strips both sides');
# ok 41
is(r("  {{- x }}  ",  {x=>'hi'}), 'hi  ', 'var whitespace control strips left only');
# ok 42
is(r("  {{ x -}}  ",  {x=>'hi'}), '  hi', 'var whitespace control strips right only');

###############################################################################
# Nested data structures
###############################################################################

# ok 43
is(r('{{ data.items[0].label }}',
    {data=>{items=>[{label=>'First'},{label=>'Second'}]}}),
   'First', 'nested: hash -> array -> hash');
# ok 44
is(r('{{ matrix[0][1] }}', {matrix=>[[1,2],[3,4]]}),
   '2', 'nested array index access');

###############################################################################
# Output of computed expressions
###############################################################################

# ok 45
is(r('{{ x + 1 }}', {x=>5}),    '6',   'expression: var + literal');
# ok 46
is(r('{{ x ~ "!" }}', {x=>'hi'}), 'hi!', 'expression: string concat with var');

###############################################################################
# loop variable (defined during for, undefined outside)
###############################################################################

# ok 47
is(r('{% for i in x %}{{ loop.index }}{% endfor %}', {x=>['a','b','c']}),
   '123', 'loop.index 1-based');
# ok 48
is(r('{% for i in x %}{{ loop.index0 }}{% endfor %}', {x=>['a','b']}),
   '01', 'loop.index0 0-based');
# ok 49
is(r('{% for i in x %}{{ loop.revindex }}{% endfor %}', {x=>['a','b','c']}),
   '321', 'loop.revindex');
# ok 50
is(r('{% for i in x %}{{ loop.revindex0 }}{% endfor %}', {x=>['a','b','c']}),
   '210', 'loop.revindex0');
# ok 51
is(r('{% for i in x %}{{ loop.length }}{% endfor %}', {x=>['a','b','c']}),
   '333', 'loop.length');
# ok 52
is(r('{% for i in x %}{% if loop.first %}F{% endif %}{% endfor %}', {x=>['a','b','c']}),
   'F', 'loop.first true only on first');
# ok 53
is(r('{% for i in x %}{% if loop.last %}L{% endif %}{% endfor %}', {x=>['a','b','c']}),
   'L', 'loop.last true only on last');
# ok 54
is(r('{% for i in x %}{{ loop.odd }}{% endfor %}', {x=>['a','b','c']}),
   '010', 'loop.odd (1st=0,2nd=1,3rd=0... wait: 1st iter idx=0 even so odd=0)');
# ok 55
is(r('{% for i in x %}{{ loop.even }}{% endfor %}', {x=>['a','b','c']}),
   '101', 'loop.even (1st iter idx=0 so even=1)');
# ok 56
is(r('{% for i in x %}{{ loop.depth }}{% endfor %}', {x=>['a']}),
   '1', 'loop.depth always 1 (no recursive for)');

END { print "# $PASS passed, $FAIL failed\n"; exit($FAIL ? 1 : 0) }
