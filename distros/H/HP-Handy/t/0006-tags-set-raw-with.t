######################################################################
#
# 0006-tags-set-raw-with.t -- set, with, raw, comment tag tests
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
# set: basic assignment
###############################################################################

# ok 1-8
is(r('{% set x = 42 %}{{ x }}'),            '42',    'set: integer');
is(r('{% set x = "hello" %}{{ x }}'),        'hello', 'set: string');
is(r('{% set x = 3.14 %}{{ x }}'),           '3.14',  'set: float');
is(r('{% set x = true %}{{ x }}'),           '1',     'set: true');
is(r('{% set x = false %}{{ x }}'),          '0',     'set: false');
is(r('{% set x = none %}{{ x is none }}'),   '1',     'set: none');
is(r('{% set x = "a" ~ "b" %}{{ x }}'),      'ab',    'set: concat expression');
is(r('{% set x = 2 + 3 %}{{ x }}'),          '5',     'set: arithmetic expression');

###############################################################################
# set: using existing variables
###############################################################################

# ok 9-13
is(r('{% set y = x %}{{ y }}', {x=>'hi'}),   'hi',  'set: copy from var');
is(r('{% set y = x ~ "!" %}{{ y }}', {x=>'ok'}), 'ok!', 'set: expr using var');
is(r('{% set y = x + 1 %}{{ y }}', {x=>5}),  '6',   'set: arithmetic with var');
is(r('{% set a = x %}{% set b = a %}{{ b }}', {x=>'v'}), 'v', 'set: chain assignment');
is(r('{% set x = x ~ x %}{{ x }}', {x=>'ab'}), 'abab', 'set: self-referential');

###############################################################################
# set: scope -- set inside if
###############################################################################

# ok 14-17
is(r('{% if 1 %}{% set x = "in_if" %}{% endif %}{{ x }}'),
   'in_if', 'set: inside if block visible outside');
is(r('{% set x = "outer" %}{% if 1 %}{% set x = "inner" %}{% endif %}{{ x }}'),
   'inner', 'set: inside if overrides outer');
is(r('{% set x = "outer" %}{% if 0 %}{% set x = "inner" %}{% endif %}{{ x }}'),
   'outer', 'set: inside false if does not override');
is(r('{% set x = "a" %}{% set x = "b" %}{{ x }}'),
   'b', 'set: second assignment overrides first');

###############################################################################
# set: list and hash literals
###############################################################################

# ok 18-20
is(r('{% set items = [1,2,3] %}{{ items|join(",") }}'),
   '1,2,3', 'set: list literal');
is(r('{% set items = [1,2,3] %}{{ items|length }}'),
   '3',     'set: list length');
is(r('{% set items = [1,2,3] %}{% for i in items %}{{ i }}{% endfor %}'),
   '123',   'set: iterate over set list');

###############################################################################
# with: scoped variables
###############################################################################

# ok 21-28
is(r('{% with x = 10 %}{{ x }}{% endwith %}'),
   '10', 'with: single var');
is(r('{% with x = 10, y = 20 %}{{ x + y }}{% endwith %}'),
   '30', 'with: two vars');
is(r('{% set x = 1 %}{% with x = 99 %}{{ x }}{% endwith %}{{ x }}'),
   '991', 'with: scoped var does not leak');
is(r('{% with a = "hello", b = "world" %}{{ a }} {{ b }}{% endwith %}'),
   'hello world', 'with: string vars');
is(r('{% with n = 5 %}{% with m = n * 2 %}{{ m }}{% endwith %}{% endwith %}'),
   '10', 'with: nested with');
is(r('{% set base = 10 %}{% with x = base + 5 %}{{ x }}{% endwith %}{{ base }}'),
   '1510', 'with: uses outer var in init');
is(r('{% with x = 1 %}{% if x %}yes{% endif %}{% endwith %}'),
   'yes', 'with: if inside with');
is(r('{% with items = [1,2,3] %}{% for i in items %}{{ i }}{% endfor %}{% endwith %}'),
   '123', 'with: for inside with');

###############################################################################
# raw: no template processing
###############################################################################

# ok 29-36
is(r('{% raw %}{{ x }}{% endraw %}', {x=>'hi'}),
   '{{ x }}', 'raw: var tag not rendered');
is(r('{% raw %}{% if 1 %}yes{% endif %}{% endraw %}'),
   '{% if 1 %}yes{% endif %}', 'raw: if tag not rendered');
is(r('{% raw %}{# comment #}{% endraw %}'),
   '{# comment #}', 'raw: comment not stripped');
is(r('before{% raw %}{{ x }}{% endraw %}after', {x=>'v'}),
   'before{{ x }}after', 'raw: surrounding text preserved');
is(r('{% raw %}{% for i in x %}{{ i }}{% endfor %}{% endraw %}', {x=>[1,2]}),
   '{% for i in x %}{{ i }}{% endfor %}', 'raw: for loop not rendered');
is(r('{% raw %}literal % and { chars{% endraw %}'),
   'literal % and { chars', 'raw: special chars pass through');
is(r('{% raw %}  spaces  {% endraw %}'),
   '  spaces  ', 'raw: whitespace preserved');
is(r('{% raw %}line1\nline2{% endraw %}'),
   'line1\nline2', 'raw: backslash not interpreted');

###############################################################################
# Comments: {# #}
###############################################################################

# ok 37-44
is(r('a{# hidden #}b'),          'ab',  'comment: inline stripped');
is(r('{# full line #}text'),      'text','comment: leading comment stripped');
is(r('text{# trailing #}'),       'text','comment: trailing comment stripped');
is(r('a{# one #}b{# two #}c'),    'abc', 'comment: multiple comments');
is(r("a{# line\ncomment #}b"),    'ab',  'comment: multiline comment stripped');
is(r('{# {% if 1 %}yes{% endif %} #}text'), 'text', 'comment: tags inside comment');
is(r('{# {{ x }} #}{{ y }}', {x=>'X',y=>'Y'}), 'Y', 'comment: var inside comment');
is(r('{% set x = "v" %}{# {% set x = "bad" %} #}{{ x }}'),
   'v', 'comment: set inside comment not executed');

###############################################################################
# Combination tests
###############################################################################

# ok 45-56
is(r('{% set items = ["a","b","c"] %}{% for i in items %}{{ loop.index }}.{{ i }}{% if not loop.last %},{% endif %}{% endfor %}'),
   '1.a,2.b,3.c', 'set+for+if: common list pattern');
is(r("{% set prefix = \"> \" %}{% for i in x %}{{ prefix }}{{ i }}\n{% endfor %}", {x=>['a','b']}),
   "> a\n> b\n", 'set+for: prefix each line');
is(r('{% with sep = ", " %}{{ items|join(sep) }}{% endwith %}', {items=>['x','y','z']}),
   'x, y, z', 'with+filter: dynamic separator');
is(r('{# skip: {% set debug = 1 %} #}{% set debug = 0 %}{{ debug }}'),
   '0', 'comment+set: commented set skipped');
is(r('{% raw %}{{ raw }}{% endraw %} and {{ real }}', {real=>'value'}),
   '{{ raw }} and value', 'raw+var: mixed rendering');
is(r('{% set x = 1 %}{% with x = 2 %}{% set x = 3 %}{{ x }}{% endwith %}{{ x }}'),
   '31', 'set+with: with isolates scope');
is(r('{% for i in range(3) %}{% set j = i * i %}{{ i }}^2={{ j }};{% endfor %}'),
   '0^2=0;1^2=1;2^2=4;', 'for+set: computed value per iteration');
is(r('{% set count = 0 %}{% for i in x %}{% if i > 0 %}{% set count = count + 1 %}{% endif %}{% endfor %}{{ count }}',
    {x=>[-1,2,-3,4,5]}), '0', 'for+set+if: accumulator is local scope (spec: cannot modify outer)');
is(r("{% with greeting = \"Hello\" %}{% for name in names %}{{ greeting }}, {{ name }}!\n{% endfor %}{% endwith %}",
    {names=>['Alice','Bob']}), "Hello, Alice!\nHello, Bob!\n", 'with+for: shared context');
is(r('{% set sep = "" %}{% for i in x %}{{ sep }}{{ i }}{% set sep = "," %}{% endfor %}',
    {x=>[1,2,3]}), '123', 'for+set: set inside for is local -- outer sep unchanged each iteration (HP::Handy spec: use join filter for this pattern)');
is(r("{# title #}\n{% set title = \"My Page\" %}{{ title }}"), "\nMy Page", 'comment+set: comment then set');
is(r('{% with n = 10 %}{# loop {{ n }} times #}{% for i in range(n) %}{{ i }}{% endfor %}{% endwith %}'),
   '0123456789', 'with+raw comment+for: combination');

END { print "# $PASS passed, $FAIL failed\n"; exit($FAIL ? 1 : 0) }
