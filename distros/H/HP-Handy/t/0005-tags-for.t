######################################################################
#
# 0005-tags-for.t -- for loop tag tests
#
# Tests: basic iteration, loop variable (all fields), else block,
# if-filter, tuple unpacking (dict), range(), nested for,
# for over string/scalar, loop.changed (basic), break/continue
# (not supported -- documented as limitation).
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

print "1..72\n";

###############################################################################
# Basic iteration
###############################################################################

# ok 1-6
is(r('{% for i in x %}{{ i }}{% endfor %}', {x=>['a','b','c']}),  'abc',  'for: string list');
is(r('{% for i in x %}{{ i }}{% endfor %}', {x=>[1,2,3]}),        '123',  'for: integer list');
is(r('{% for i in x %}{{ i }},{% endfor %}',{x=>['a','b']}),      'a,b,', 'for: with comma separator');
is(r('{% for i in x %}{% endfor %}',        {x=>[1,2,3]}),        '',     'for: empty body');
is(r('{% for i in x %}{{ i }}{% endfor %}', {x=>[42]}),           '42',   'for: single element');
is(r('{% for i in x %}x{% endfor %}',       {x=>[1,2,3,4,5]}),    'xxxxx','for: 5 iterations');

###############################################################################
# loop.index / loop.index0
###############################################################################

# ok 7-10
is(r('{% for i in x %}{{ loop.index }}{% endfor %}', {x=>['a','b','c']}),
   '123', 'loop.index: 1-based');
is(r('{% for i in x %}{{ loop.index0 }}{% endfor %}', {x=>['a','b','c']}),
   '012', 'loop.index0: 0-based');
is(r('{% for i in x %}{{ loop.index }}/{{ loop.index0 }} {% endfor %}', {x=>['a','b']}),
   '1/0 2/1 ', 'loop.index and index0 together');
is(r('{% for i in x %}{{ i }}={{ loop.index }}{% if not loop.last %},{% endif %}{% endfor %}',
    {x=>['a','b','c']}), 'a=1,b=2,c=3', 'loop.index with separator');

###############################################################################
# loop.revindex / loop.revindex0
###############################################################################

# ok 11-12
is(r('{% for i in x %}{{ loop.revindex }}{% endfor %}', {x=>['a','b','c']}),
   '321', 'loop.revindex: descending');
is(r('{% for i in x %}{{ loop.revindex0 }}{% endfor %}', {x=>['a','b','c']}),
   '210', 'loop.revindex0: descending from 0');

###############################################################################
# loop.first / loop.last
###############################################################################

# ok 13-18
is(r('{% for i in x %}{% if loop.first %}[{{ i }}{% else %}{{ i }}{% endif %}{% if loop.last %}]{% endif %}{% endfor %}',
    {x=>['a','b','c']}), '[abc]', 'loop.first/last: bracket wrapping');
is(r('{% for i in x %}{% if loop.first %}F{% endif %}{{ i }}{% endfor %}',
    {x=>[1,2,3]}), 'F123', 'loop.first: only on first');
is(r('{% for i in x %}{{ i }}{% if loop.last %}!{% endif %}{% endfor %}',
    {x=>[1,2,3]}), '123!', 'loop.last: only on last');
is(r('{% for i in x %}{{ "," if not loop.first else "" }}{{ i }}{% endfor %}',
    {x=>['a','b','c']}), 'a,b,c', 'loop.first: join pattern');
is(r('{% for i in x %}{{ loop.first }},{% endfor %}', {x=>['a','b','c']}),
   '1,0,0,', 'loop.first: numeric values');
is(r('{% for i in x %}{{ loop.last }},{% endfor %}', {x=>['a','b','c']}),
   '0,0,1,', 'loop.last: numeric values');

###############################################################################
# loop.length / loop.odd / loop.even
###############################################################################

# ok 19-22
is(r('{% for i in x %}{{ loop.length }}{% endfor %}', {x=>['a','b','c']}),
   '333', 'loop.length: constant within loop');
is(r('{% for i in x %}{{ loop.odd }}{% endfor %}', {x=>[1,2,3,4]}),
   '0101', 'loop.odd: alternates starting false (0-indexed)');
is(r('{% for i in x %}{{ loop.even }}{% endfor %}', {x=>[1,2,3,4]}),
   '1010', 'loop.even: alternates starting true (0-indexed)');
is(r('{% for i in x %}{% if loop.even %}{{ i }}{% endif %}{% endfor %}',
    {x=>[1,2,3,4]}), '13', 'loop.even: select 1st/3rd items');

###############################################################################
# for / else
###############################################################################

# ok 23-27
is(r('{% for i in x %}{{ i }}{% else %}none{% endfor %}', {x=>['a']}),
   'a', 'for/else: non-empty uses body');
is(r('{% for i in x %}{{ i }}{% else %}none{% endfor %}', {x=>[]}),
   'none', 'for/else: empty list uses else');
is(r('{% for i in x %}{{ i }}{% else %}none{% endfor %}', {}),
   'none', 'for/else: undefined list uses else');
is(r('{% for i in x %}{{ i }}{% else %}<empty>{% endfor %}',{x=>[]}),
   '<empty>', 'for/else: HTML in else block');
is(r('A{% for i in x %}{{ i }}{% else %}B{% endfor %}C', {x=>[]}),
   'ABC', 'for/else: surrounding text preserved');

###############################################################################
# for with if filter
###############################################################################

# ok 28-34
is(r('{% for i in x if i > 2 %}{{ i }}{% endfor %}', {x=>[1,2,3,4,5]}),
   '345', 'for if: filter by comparison');
is(r('{% for i in x if i != "b" %}{{ i }}{% endfor %}', {x=>['a','b','c']}),
   'ac', 'for if: exclude element by string comparison');
is(r('{% for i in x if i %}{{ i }}{% endfor %}', {x=>[0,'',1,'a']}),
   '1a', 'for if: filter falsy values');
is(r('{% for i in x if i is odd %}{{ i }}{% endfor %}', {x=>[1,2,3,4,5]}),
   '135', 'for if: filter by is test');
is(r('{% for i in x if i > 0 %}{{ loop.index }}{% endfor %}', {x=>[-1,1,2,3]}),
   '123', 'for if: loop.index counts filtered items');
is(r('{% for i in x if i > 10 %}{{ i }}{% else %}none{% endfor %}', {x=>[1,2,3]}),
   'none', 'for if: all filtered out uses else');
is(r('{% for i in x if i > 0 %}{{ i }}{% else %}none{% endfor %}', {x=>[1,2,3]}),
   '123', 'for if: partial filter no else');

###############################################################################
# Dict iteration (key, value pairs)
###############################################################################

# ok 35-39
is(r('{% for k, v in d %}{{ k }}={{ v }};{% endfor %}',
    {d=>{a=>1,b=>2}}), 'a=1;b=2;', 'for dict: key/value pairs sorted');
is(r('{% for k, v in d %}{{ k }}{% endfor %}',
    {d=>{x=>10,y=>20,z=>30}}), 'xyz', 'for dict: keys only');
is(r('{% for k, v in d %}{{ v }}{% endfor %}',
    {d=>{a=>1,b=>2,c=>3}}), '123', 'for dict: values only');
is(r('{% for k, v in d %}{{ loop.index }}.{{ k }}{% endfor %}',
    {d=>{p=>1,q=>2}}), '1.p2.q', 'for dict: loop.index works');
is(r('{% for k, v in d %}{% endfor %}', {d=>{}}),
   '', 'for dict: empty hash');

###############################################################################
# range()
###############################################################################

# ok 40-47
is(r('{% for i in range(3) %}{{ i }}{% endfor %}'),    '012',  'range(3): 0,1,2');
is(r('{% for i in range(1,4) %}{{ i }}{% endfor %}'),  '123',  'range(1,4): 1,2,3');
is(r('{% for i in range(0,10,2) %}{{ i }}{% endfor %}'),'02468','range(0,10,2): evens');
is(r('{% for i in range(5,0,-1) %}{{ i }}{% endfor %}'),'54321','range(5,0,-1): countdown');
is(r('{% for i in range(0) %}{{ i }}{% else %}none{% endfor %}'), 'none', 'range(0): empty');
is(r('{% for i in range(1) %}{{ i }}{% endfor %}'),    '0',    'range(1): single element');
is(r('{% for i in range(3,3) %}{{ i }}{% else %}e{% endfor %}'), 'e', 'range(3,3): empty range');
is(r('{% for i in range(x) %}{{ i }}{% endfor %}', {x=>3}), '012', 'range(var): from variable');

###############################################################################
# Nested for loops
###############################################################################

# ok 48-53
is(r('{% for i in a %}{% for j in b %}{{ i }}{{ j }}{% endfor %}{% endfor %}',
    {a=>[1,2], b=>['a','b']}), '1a1b2a2b', 'nested for: 2x2');
is(r('{% for i in a %}{% for j in b %}{{ loop.index }}{% endfor %}{% endfor %}',
    {a=>[1,2], b=>['x','y','z']}), '123123', 'nested for: inner loop.index resets');
is(r('{% for i in a %}{{ loop.index }}:{% for j in b %}{{ j }}{% endfor %};{% endfor %}',
    {a=>['A','B'], b=>[1,2,3]}), '1:123;2:123;', 'nested for: outer index maintained');
is(r('{% for row in m %}{% for cell in row %}{{ cell }}{% endfor %}|{% endfor %}',
    {m=>[[1,2],[3,4],[5,6]]}), '12|34|56|', 'nested for: matrix traversal');
is(r('{% for i in a %}{% for j in b if j > i %}{{ i }}{{ j }}{% endfor %}{% endfor %}',
    {a=>[1,2], b=>[1,2,3]}), '121323', 'nested for: inner with if filter (i=1:j=2,3; i=2:j=3)');
is(r('{% for i in range(3) %}{% for j in range(i+1) %}{{ j }}{% endfor %};{% endfor %}'),
   '0;01;012;', 'nested for: triangular with range');

###############################################################################
# for with set inside
###############################################################################

# ok 54-56
is(r('{% for i in x %}{% set msg = i ~ "!" %}{{ msg }}{% endfor %}',
    {x=>['a','b']}), 'a!b!', 'for with set: local assignment');
is(r('{% set total = 0 %}{% for i in x %}{% set total = total + i %}{% endfor %}{{ total }}',
    {x=>[1,2,3]}), '0', 'for with set: set inside for is local scope -- outer var unchanged (HP::Handy spec)');
is(r('{% for i in x %}{% set j = i * 2 %}{{ j }},{% endfor %}',
    {x=>[1,2,3]}), '2,4,6,', 'for with set: derived variable');

###############################################################################
# for with complex body
###############################################################################

# ok 57-62
is(r('<ul>{% for i in x %}<li>{{ i }}</li>{% endfor %}</ul>',
    {x=>['a','b','c']}), '<ul><li>a</li><li>b</li><li>c</li></ul>',
    'for: HTML list generation');
is(r('{% for u in users %}{{ u.name }}({{ u.age }}){% if not loop.last %}, {% endif %}{% endfor %}',
    {users=>[{name=>'Alice',age=>30},{name=>'Bob',age=>25}]}),
   'Alice(30), Bob(25)', 'for: object list with join');
is(r('{% for item in items %}{% if item.active %}{{ item.name }}{% endif %}{% endfor %}',
    {items=>[{name=>'A',active=>1},{name=>'B',active=>0},{name=>'C',active=>1}]}),
   'AC', 'for: filter by attribute in body');
is(r('{% for n in nums %}{{ n|format("%3d") }}{% endfor %}',
    {nums=>[1,10,100]}), '  1 10100', 'for: formatted output with format filter');
is(r('{% for i in range(1,4) %}{{ i }}{% if not loop.last %}+{% endif %}{% endfor %}={{ sum }}',
    {sum=>6}), '1+2+3=6', 'for: arithmetic expression display');
is(r("{% for row in table %}|{% for cell in row %}{{ cell|format('%-5s') }}|{% endfor %}\n{% endfor %}",
    {table=>[['A','B'],['C','D']]}),
   "|A    |B    |\n|C    |D    |\n", 'for: table formatting with format filter');

###############################################################################
# for over list of different types
###############################################################################

# ok 63-67
is(r('{% for i in x %}{{ i }}{% endfor %}', {x=>[0,1,2]}),
   '012', 'for: includes 0');
is(r('{% for i in x %}{{ i }}{% endfor %}', {x=>['',1,'a']}),
   '1a', 'for: empty string is falsy but still iterated');
is(r('{% for i in x %}{{ i if i else "-" }}{% endfor %}', {x=>['a','','b']}),
   'a-b', 'for: inline conditional in loop body');
is(r('{% for i in x|sort %}{{ i }}{% endfor %}', {x=>['c','a','b']}),
   'abc', 'for: iterate over filtered list');
is(r('{% for i in x|reverse %}{{ i }}{% endfor %}', {x=>[1,2,3]}),
   '321', 'for: iterate over reversed list');

###############################################################################
# for: empty string iteration (spec: string not iterable in HP::Handy)
###############################################################################

# ok 68-72
is(r('{% for i in x %}{{ i }}{% endfor %}', {x=>'scalar'}),
   'scalar', 'for scalar: wraps single value');
is(r('{% for i in x %}{{ loop.length }}{% endfor %}', {x=>'s'}),
   '1', 'for scalar: length is 1');
is(r('{% for i in x %}{{ loop.first }}{{ loop.last }}{% endfor %}', {x=>'v'}),
   '11', 'for scalar: first and last both true');
is(r('{% for i in x if i > 0 %}{{ i }}{% endfor %}', {x=>5}),
   '5', 'for scalar with if filter: passes');
is(r('{% for i in x if i > 10 %}{{ i }}{% else %}none{% endfor %}', {x=>5}),
   'none', 'for scalar with if filter: fails uses else');

END { print "# $PASS passed, $FAIL failed\n"; exit($FAIL ? 1 : 0) }
