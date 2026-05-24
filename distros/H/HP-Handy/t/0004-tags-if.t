######################################################################
#
# 0004-tags-if.t -- if / elif / else / endif tag tests
#
# Tests: basic if, elif chains, else, nested if, inline conditional,
# if with comparison operators, if with boolean operators,
# if with is tests, deeply nested conditions.
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

print "1..68\n";

###############################################################################
# Basic if / endif
###############################################################################

# ok 1-6
is(r('{% if 1 %}yes{% endif %}'),         'yes', 'if true literal 1');
is(r('{% if 0 %}yes{% endif %}'),         '',    'if false literal 0');
is(r('{% if true %}yes{% endif %}'),      'yes', 'if true keyword');
is(r('{% if false %}yes{% endif %}'),     '',    'if false keyword');
is(r('{% if x %}yes{% endif %}', {x=>1}),'yes', 'if var truthy');
is(r('{% if x %}yes{% endif %}', {x=>0}),'',    'if var falsy (0)');

###############################################################################
# if with undefined variable
###############################################################################

# ok 7-9
is(r('{% if x %}yes{% endif %}', {}),    '',    'if undefined var is falsy');
is(r('{% if x %}yes{% endif %}', {x=>undef}), '', 'if undef is falsy');
is(r('{% if x %}yes{% else %}no{% endif %}', {}), 'no', 'if/else undefined');

###############################################################################
# if / else
###############################################################################

# ok 10-14
is(r('{% if x %}A{% else %}B{% endif %}', {x=>1}),  'A', 'if/else: true branch');
is(r('{% if x %}A{% else %}B{% endif %}', {x=>0}),  'B', 'if/else: false branch');
is(r('{% if x %}A{% else %}B{% endif %}', {}),       'B', 'if/else: undef uses else');
is(r('A{% if x %}B{% endif %}C', {x=>1}),  'ABC',  'if: text before and after');
is(r('A{% if x %}B{% endif %}C', {x=>0}),  'AC',   'if false: text before and after');

###############################################################################
# if / elif / else chains
###############################################################################

# ok 15-22
is(r('{% if x==1 %}A{% elif x==2 %}B{% else %}C{% endif %}', {x=>1}), 'A', 'elif: first branch');
is(r('{% if x==1 %}A{% elif x==2 %}B{% else %}C{% endif %}', {x=>2}), 'B', 'elif: second branch');
is(r('{% if x==1 %}A{% elif x==2 %}B{% else %}C{% endif %}', {x=>3}), 'C', 'elif: else branch');
is(r('{% if x<0 %}neg{% elif x==0 %}zero{% elif x>0 %}pos{% endif %}', {x=>-1}), 'neg',  'elif chain: negative');
is(r('{% if x<0 %}neg{% elif x==0 %}zero{% elif x>0 %}pos{% endif %}', {x=>0}),  'zero', 'elif chain: zero');
is(r('{% if x<0 %}neg{% elif x==0 %}zero{% elif x>0 %}pos{% endif %}', {x=>1}),  'pos',  'elif chain: positive');
is(r('{% if x>=90 %}A{% elif x>=70 %}B{% elif x>=50 %}C{% else %}F{% endif %}', {x=>95}), 'A', 'grade: A');
is(r('{% if x>=90 %}A{% elif x>=70 %}B{% elif x>=50 %}C{% else %}F{% endif %}', {x=>45}), 'F', 'grade: F');

###############################################################################
# Nested if
###############################################################################

# ok 23-28
is(r('{% if x %}{% if y %}both{% else %}x only{% endif %}{% endif %}',
    {x=>1, y=>1}),   'both',   'nested if: both true');
is(r('{% if x %}{% if y %}both{% else %}x only{% endif %}{% endif %}',
    {x=>1, y=>0}),   'x only', 'nested if: x true y false');
is(r('{% if x %}{% if y %}both{% else %}x only{% endif %}{% endif %}',
    {x=>0, y=>1}),   '',       'nested if: x false skips inner');
is(r('{% if x %}A{% if y %}B{% endif %}C{% endif %}',
    {x=>1, y=>1}), 'ABC', 'nested if: inner true');
is(r('{% if x %}A{% if y %}B{% endif %}C{% endif %}',
    {x=>1, y=>0}), 'AC',  'nested if: inner false');
is(r('{% if a %}{% if b %}{% if c %}deep{% endif %}{% endif %}{% endif %}',
    {a=>1, b=>1, c=>1}), 'deep', 'deeply nested if: true');

###############################################################################
# Comparison operators in if
###############################################################################

# ok 29-40
is(r('{% if x == 5 %}y{% endif %}',  {x=>5}),  'y', '== true');
is(r('{% if x == 5 %}y{% endif %}',  {x=>6}),  '',  '== false');
is(r('{% if x != 5 %}y{% endif %}',  {x=>6}),  'y', '!= true');
is(r('{% if x != 5 %}y{% endif %}',  {x=>5}),  '',  '!= false');
is(r('{% if x > 3 %}y{% endif %}',   {x=>5}),  'y', '> true');
is(r('{% if x > 5 %}y{% endif %}',   {x=>5}),  '',  '> false (equal)');
is(r('{% if x < 5 %}y{% endif %}',   {x=>3}),  'y', '< true');
is(r('{% if x < 5 %}y{% endif %}',   {x=>5}),  '',  '< false (equal)');
is(r('{% if x >= 5 %}y{% endif %}',  {x=>5}),  'y', '>= equal');
is(r('{% if x >= 5 %}y{% endif %}',  {x=>4}),  '',  '>= false');
is(r('{% if x <= 5 %}y{% endif %}',  {x=>5}),  'y', '<= equal');
is(r('{% if x <= 5 %}y{% endif %}',  {x=>6}),  '',  '<= false');

###############################################################################
# Boolean operators in if
###############################################################################

# ok 41-50
is(r('{% if x and y %}y{% endif %}', {x=>1, y=>1}), 'y', 'and: both true');
is(r('{% if x and y %}y{% endif %}', {x=>1, y=>0}), '',  'and: second false');
is(r('{% if x and y %}y{% endif %}', {x=>0, y=>1}), '',  'and: first false');
is(r('{% if x or y %}y{% endif %}',  {x=>0, y=>1}), 'y', 'or: second true');
is(r('{% if x or y %}y{% endif %}',  {x=>1, y=>0}), 'y', 'or: first true');
is(r('{% if x or y %}y{% endif %}',  {x=>0, y=>0}), '',  'or: both false');
is(r('{% if not x %}y{% endif %}',   {x=>0}),        'y', 'not: falsy');
is(r('{% if not x %}y{% endif %}',   {x=>1}),        '',  'not: truthy');
is(r('{% if x and not y %}y{% endif %}', {x=>1, y=>0}), 'y', 'and not');
is(r('{% if not x or y %}y{% endif %}',  {x=>0, y=>0}), 'y', 'not or');

###############################################################################
# String comparison in if
###############################################################################

# ok 51-56
is(r('{% if x == "hello" %}y{% endif %}', {x=>'hello'}), 'y', 'string ==');
is(r('{% if x == "hello" %}y{% endif %}', {x=>'world'}), '',  'string == false');
is(r('{% if x != "hello" %}y{% endif %}', {x=>'world'}), 'y', 'string !=');
is(r('{% if x != "" %}y{% endif %}', {x=>'val'}),        'y', 'string != empty');
is(r('{% if x == "" %}y{% endif %}', {x=>''}),           'y', 'string == empty');
is(r('{% if x %}y{% endif %}',        {x=>'0'}),         '',  'string "0" is falsy in Perl (HP::Handy spec: Perl truthiness rules apply)');

###############################################################################
# Inline conditional (ternary)
###############################################################################

# ok 57-64
is(r('{{ "y" if x else "n" }}',        {x=>1}),     'y',  'inline if: true');
is(r('{{ "y" if x else "n" }}',        {x=>0}),     'n',  'inline if: false');
is(r('{{ "y" if x else "n" }}',        {}),         'n',  'inline if: undef');
is(r('{{ x if x else "none" }}',       {x=>'hi'}),  'hi', 'inline if: value from var');
is(r('{{ x if x else "none" }}',       {}),         'none','inline if: missing var');
is(r('{{ a+b if a else 0 }}',          {a=>3,b=>4}),'7',  'inline if: expression branch');
is(r('{{ "big" if x > 10 else "small" }}', {x=>15}), 'big',  'inline if: comparison true');
is(r('{{ "big" if x > 10 else "small" }}', {x=>5}),  'small','inline if: comparison false');

###############################################################################
# if with is tests
###############################################################################

# ok 65-68
is(r('{% if x is defined %}y{% endif %}',   {x=>1}), 'y', 'if is defined');
is(r('{% if x is none %}y{% endif %}',       {}),     'y', 'if is none');
is(r('{% if x is odd %}y{% endif %}',       {x=>3}), 'y', 'if is odd');
is(r('{% if x is not even %}y{% endif %}',  {x=>3}), 'y', 'if is not even');

END { print "# $PASS passed, $FAIL failed\n"; exit($FAIL ? 1 : 0) }
