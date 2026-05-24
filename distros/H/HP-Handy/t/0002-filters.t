######################################################################
#
# 0002-filters.t -- Built-in filter tests
#
# Tests all 40 built-in filters with:
#   - normal input
#   - edge cases (empty, undef, numeric, unicode-safe ASCII)
#   - filter argument variations
#   - filter pipeline chaining
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

print "1..141\n";

###############################################################################
# upper / lower
###############################################################################

# ok 1-4
is(r('{{ x|upper }}', {x=>'hello'}),   'HELLO',   'upper: lowercase input');
is(r('{{ x|upper }}', {x=>'Hello'}),   'HELLO',   'upper: mixed input');
is(r('{{ x|lower }}', {x=>'HELLO'}),   'hello',   'lower: uppercase input');
is(r('{{ x|lower }}', {x=>'Hello'}),   'hello',   'lower: mixed input');

###############################################################################
# title / capitalize
###############################################################################

# ok 5-8
is(r('{{ x|title }}',      {x=>'hello world'}), 'Hello World', 'title: normal');
is(r('{{ x|title }}',      {x=>'HELLO'}),        'HELLO',      'title: already upper stays upper');
is(r('{{ x|capitalize }}', {x=>'hello world'}),  'Hello world','capitalize: first letter only');
is(r('{{ x|capitalize }}', {x=>'HELLO'}),        'Hello',      'capitalize: lowercases rest');

###############################################################################
# trim
###############################################################################

# ok 9-12
is(r('{{ x|trim }}', {x=>'  hi  '}),  'hi',    'trim: both sides');
is(r('{{ x|trim }}', {x=>'  hi'}),    'hi',    'trim: left only');
is(r('{{ x|trim }}', {x=>'hi  '}),    'hi',    'trim: right only');
is(r('{{ x|trim }}', {x=>''}),        '',      'trim: empty string');

###############################################################################
# length / count
###############################################################################

# ok 13-18
is(r('{{ x|length }}', {x=>'hello'}),       '5', 'length: string');
is(r('{{ x|length }}', {x=>''}),            '0', 'length: empty string');
is(r('{{ x|length }}', {x=>[1,2,3]}),       '3', 'length: list');
is(r('{{ x|count }}',  {x=>[1,2,3,4]}),     '4', 'count: list');
is(r('{{ x|count }}',  {x=>[]}),            '0', 'count: empty list');
is(r('{{ x|length }}', {x=>{a=>1,b=>2}}),   '2', 'length: undef returns 0 for hash -- actually returns length of ref string; use count instead');

###############################################################################
# reverse
###############################################################################

# ok 19-21
is(r('{{ x|reverse }}', {x=>'abc'}),         'cba',   'reverse: string');
is(r('{{ x|reverse }}', {x=>''}),            '',      'reverse: empty string');
is(r('{{ x|reverse|join(",") }}', {x=>['a','b','c']}), 'c,b,a', 'reverse: list');

###############################################################################
# escape / e / forceescape
###############################################################################

# ok 22-27
is(r('{{ x|escape }}', {x=>'<b>'}),      '&lt;b&gt;',  'escape: angle brackets');
is(r('{{ x|escape }}', {x=>'"hi"'}),     '&quot;hi&quot;', 'escape: double quotes');
is(r("{{ x|escape }}", {x=>"it's"}),     'it&#39;s',    'escape: single quote in string');
is(r('{{ x|e }}',      {x=>'<'}),        '&lt;',       'e alias for escape');
is(r('{{ x|escape }}', {x=>'&amp;'}),    '&amp;amp;',  'escape: ampersand double-escapes');
is(r('{{ x|forceescape }}', {x=>'<b>'}), '&lt;b&gt;',  'forceescape: same as escape');

###############################################################################
# safe
###############################################################################

# ok 28-30
is(HP::Handy->new(auto_escape=>1)->render_string('{{ x|safe }}', {x=>'<b>'}),
   '<b>', 'safe: bypasses auto_escape');
is(HP::Handy->new(auto_escape=>1)->render_string('{{ x }}', {x=>'<b>'}),
   '&lt;b&gt;', 'without safe: auto_escape applies');
is(r('{{ x|safe }}', {x=>'<b>'}), '<b>', 'safe: no-op when auto_escape off');

###############################################################################
# default / d
###############################################################################

# ok 31-36
is(r('{{ x|default("none") }}', {}),              'none',  'default: undefined var');
is(r('{{ x|default("none") }}', {x=>'hi'}),       'hi',    'default: defined value returned');
is(r('{{ x|default("none") }}', {x=>''}),         'none',  'default: empty string uses default');
is(r('{{ x|default("(n/a)") }}', {}),             '(n/a)', 'default: parens in default value');
is(r('{{ x|d("fallback") }}',   {}),              'fallback', 'd alias for default');
is(r('{{ x|default(0) }}',      {}),              '0',     'default: numeric default 0');

###############################################################################
# replace
###############################################################################

# ok 37-41
is(r('{{ x|replace("a","b") }}', {x=>'cat'}),     'cbt',   'replace: single char');
is(r('{{ x|replace("l","r") }}', {x=>'hello'}),   'herro', 'replace: multiple occurrences');
is(r('{{ x|replace("x","y") }}', {x=>'cat'}),     'cat',   'replace: no match');
is(r('{{ x|replace("","x") }}',  {x=>'ab'}),      'ab',    'replace: empty from (no-op)');
is(r('{{ x|replace("cat","") }}',{x=>'the cat'}), 'the ',  'replace: to empty string');

###############################################################################
# truncate
###############################################################################

# ok 42-46
is(r('{{ x|truncate(5) }}',  {x=>'hello world'}), 'hello...', 'truncate: basic');
is(r('{{ x|truncate(11) }}', {x=>'hello world'}), 'hello world', 'truncate: exact length no ellipsis');
is(r('{{ x|truncate(3,"!") }}', {x=>'hello'}),    'hel!',    'truncate: custom suffix');
is(r('{{ x|truncate(20) }}', {x=>'short'}),       'short',   'truncate: shorter than limit');
is(r('{{ x|truncate(0) }}',  {x=>'hello'}),       '...',     'truncate: zero length');

###############################################################################
# join
###############################################################################

# ok 47-51
is(r('{{ x|join(",") }}',  {x=>['a','b','c']}), 'a,b,c',  'join: comma');
is(r('{{ x|join(" ") }}',  {x=>['a','b']}),     'a b',    'join: space');
is(r('{{ x|join("") }}',   {x=>['a','b','c']}), 'abc',    'join: empty separator');
is(r('{{ x|join(", ") }}', {x=>[]}),            '',       'join: empty list');
is(r('{{ x|join(",") }}',  {x=>['single']}),    'single', 'join: single element');

###############################################################################
# first / last
###############################################################################

# ok 52-55
is(r('{{ x|first }}', {x=>['a','b','c']}), 'a', 'first: returns first');
is(r('{{ x|last }}',  {x=>['a','b','c']}), 'c', 'last: returns last');
is(r('{{ x|first }}', {x=>['only']}),      'only', 'first: single element');
is(r('{{ x|last }}',  {x=>['only']}),      'only', 'last: single element');

###############################################################################
# abs / int / float / string
###############################################################################

# ok 56-63
is(r('{{ x|abs }}',   {x=>-5}),    '5',   'abs: negative');
is(r('{{ x|abs }}',   {x=>5}),     '5',   'abs: positive');
is(r('{{ x|abs }}',   {x=>0}),     '0',   'abs: zero');
is(r('{{ x|int }}',   {x=>3.9}),   '3',   'int: truncates');
is(r('{{ x|int }}',   {x=>-3.9}),  '-3',  'int: negative truncates toward zero');
is(r('{{ x|int }}',   {x=>'42'}),  '42',  'int: string number');
is(r('{{ x|float }}', {x=>3}),     '3',   'float: integer');
is(r('{{ x|string }}', {x=>42}),   '42',  'string: integer to string');

###############################################################################
# urlencode
###############################################################################

# ok 64-67
is(r('{{ x|urlencode }}', {x=>'a b'}),      'a%20b',      'urlencode: space');
is(r('{{ x|urlencode }}', {x=>'a+b'}),      'a%2Bb',      'urlencode: plus');
is(r('{{ x|urlencode }}', {x=>'a/b'}),      'a%2Fb',      'urlencode: slash');
is(r('{{ x|urlencode }}', {x=>'abc123'}),   'abc123',     'urlencode: no encoding needed');

###############################################################################
# wordcount
###############################################################################

# ok 68-71
is(r('{{ x|wordcount }}', {x=>'one two three'}), '3', 'wordcount: 3 words');
is(r('{{ x|wordcount }}', {x=>'single'}),        '1', 'wordcount: 1 word');
is(r('{{ x|wordcount }}', {x=>''}),              '0', 'wordcount: empty string');
is(r('{{ x|wordcount }}', {x=>'  a  b  '}),      '2', 'wordcount: extra whitespace');

###############################################################################
# nl2br
###############################################################################

# ok 72-74
is(r('{{ x|nl2br|safe }}', {x=>"line1\nline2"}),       "line1<br>\nline2",    'nl2br: single newline');
is(r('{{ x|nl2br|safe }}', {x=>"a\nb\nc"}),            "a<br>\nb<br>\nc",     'nl2br: multiple newlines');
is(r('{{ x|nl2br|safe }}', {x=>'no newlines'}),        'no newlines',          'nl2br: no newlines');

###############################################################################
# striptags
###############################################################################

# ok 75-78
is(r('{{ x|striptags }}', {x=>'<b>bold</b>'}),          'bold',        'striptags: bold tag');
is(r('{{ x|striptags }}', {x=>'<a href="x">link</a>'}), 'link',        'striptags: anchor with attr');
is(r('{{ x|striptags }}', {x=>'no tags here'}),         'no tags here','striptags: no tags');
is(r('{{ x|striptags }}', {x=>'<br>'}),                 '',            'striptags: self-closing');

###############################################################################
# format
###############################################################################

# ok 79-82
is(r('{{ x|format("%.2f") }}', {x=>3.14159}), '3.14',  'format: float');
is(r('{{ x|format("%05d") }}', {x=>42}),      '00042', 'format: zero-padded int');
is(r('{{ x|format("%s!") }}',  {x=>'hi'}),    'hi!',   'format: string format');
is(r('{{ x|format("%x") }}',   {x=>255}),     'ff',    'format: hex');

###############################################################################
# center / indent
###############################################################################

# ok 83-87
is(r('{{ x|center(9) }}',  {x=>'hi'}),      '   hi    ', 'center: even padding');
is(r('{{ x|center(7) }}',  {x=>'hi'}),      '  hi   ',   'center: odd padding');
is(r('{{ x|center(2) }}',  {x=>'hi'}),      'hi',         'center: no padding needed');
is(r('{{ x|indent(4) }}',  {x=>"a\nb\nc"}), "a\n    b\n    c", 'indent: subsequent lines only');
is(r('{{ x|indent(4,1) }}',{x=>"a\nb"}),    "    a\n    b",    'indent: first line too');

###############################################################################
# sort / unique
###############################################################################

# ok 88-93
is(r('{{ x|sort|join(",") }}', {x=>['c','a','b']}),       'a,b,c',     'sort: strings');
is(r('{{ x|sort|join(",") }}', {x=>['3','1','2']}),        '1,2,3',     'sort: numeric strings');
is(r('{{ x|sort("name")|map("name")|join(",") }}',
    {x=>[{name=>'Bob'},{name=>'Alice'},{name=>'Carol'}]}), 'Alice,Bob,Carol', 'sort by attr');
is(r('{{ x|unique|sort|join(",") }}', {x=>['b','a','b','c','a']}), 'a,b,c', 'unique then sort');
is(r('{{ x|unique|join(",") }}', {x=>['a']}),              'a',         'unique: single element');
is(r('{{ x|unique|join(",") }}', {x=>[]}),                 '',          'unique: empty list');

###############################################################################
# min / max / sum
###############################################################################

# ok 94-99
is(r('{{ x|min }}', {x=>[3,1,2]}),     '1', 'min: integers');
is(r('{{ x|max }}', {x=>[3,1,2]}),     '3', 'max: integers');
is(r('{{ x|sum }}', {x=>[1,2,3,4]}),   '10','sum: basic');
is(r('{{ x|sum }}', {x=>[]}),          '0', 'sum: empty list');
is(r('{{ x|min }}', {x=>[-5,0,5]}),    '-5','min: with negatives');
is(r('{{ x|max }}', {x=>[-5,0,5]}),    '5', 'max: with negatives');

###############################################################################
# map / select / reject
###############################################################################

# ok 100-105
is(r('{{ x|map("name")|join(",") }}',
    {x=>[{name=>'A'},{name=>'B'}]}),    'A,B',  'map: extract attr');
is(r('{{ x|map("score")|join(",") }}',
    {x=>[{score=>90},{score=>80}]}),    '90,80','map: extract numeric attr');
is(r('{{ x|select("active")|map("name")|join(",") }}',
    {x=>[{name=>'A',active=>1},{name=>'B',active=>0},{name=>'C',active=>1}]}),
   'A,C', 'select: filter by truthy attr');
is(r('{{ x|reject("active")|map("name")|join(",") }}',
    {x=>[{name=>'A',active=>1},{name=>'B',active=>0}]}),
   'B', 'reject: filter by falsy attr');
is(r('{{ x|map("v")|sum }}', {x=>[{v=>1},{v=>2},{v=>3}]}), '6', 'map then sum');
is(r('{{ x|select("ok")|count }}',
    {x=>[{ok=>1},{ok=>0},{ok=>1}]}),   '2', 'select then count');

###############################################################################
# batch / slice
###############################################################################

# ok 106-114
is(r('{% for row in x|batch(2) %}{{ row|join(",") }};{% endfor %}',
    {x=>[1,2,3,4]}),      '1,2;3,4;',       'batch: even split');
is(r('{% for row in x|batch(2) %}{{ row|join(",") }};{% endfor %}',
    {x=>[1,2,3]}),        '1,2;3;',         'batch: odd last chunk');
is(r('{% for row in x|batch(2,"x") %}{{ row|join(",") }};{% endfor %}',
    {x=>[1,2,3]}),        '1,2;3,x;',       'batch: fill missing');
is(r('{% for col in x|slice(2) %}{{ col|join(",") }};{% endfor %}',
    {x=>[1,2,3,4]}),      '1,2;3,4;',       'slice: even split into 2');
is(r('{% for col in x|slice(3) %}{{ col|join(",") }};{% endfor %}',
    {x=>[1,2,3,4,5,6]}),  '1,2;3,4;5,6;',  'slice: split into 3');
is(r('{% for col in x|slice(2) %}{{ col|join(",") }};{% endfor %}',
    {x=>[1,2,3]}),        '1,2;3;',         'slice: uneven distributes first');
is(r('{{ x|batch(3)|first|join(",") }}', {x=>[1,2,3,4,5]}),
   '1,2,3', 'batch then first');
is(r('{{ x|slice(2)|last|join(",") }}', {x=>[1,2,3,4]}),
   '3,4',   'slice then last');
is(r('{{ x|batch(1)|count }}', {x=>[1,2,3]}), '3', 'batch(1) count equals length');

###############################################################################
# xmlattr
###############################################################################

# ok 115-117
is(r('{{ x|xmlattr|safe }}', {x=>{id=>'main',class=>'box'}}),
   'class="box" id="main"', 'xmlattr: two attrs sorted');
is(r('{{ x|xmlattr|safe }}', {x=>{href=>'http://example.com'}}),
   'href="http://example.com"', 'xmlattr: url value');
is(r('{{ x|xmlattr|safe }}', {x=>{}}), '', 'xmlattr: empty hash');

###############################################################################
# tojson
###############################################################################

# ok 118-124
is(r('{{ x|tojson|safe }}', {x=>'hello'}),          '"hello"',      'tojson: string');
is(r('{{ x|tojson|safe }}', {x=>42}),               '42',           'tojson: integer');
is(r('{{ x|tojson|safe }}', {x=>[1,2,3]}),          '[1,2,3]',      'tojson: array');
is(r('{{ x|tojson|safe }}', {x=>{}}),               '{}',           'tojson: empty hash');
is(r('{{ x|tojson|safe }}', {x=>[1,'a',2]}),        '[1,"a",2]',    'tojson: mixed array');
is(r('{{ x|tojson|safe }}', {x=>undef}),            'null',         'tojson: undef -> null');
is(r('{{ x|tojson|safe }}', {x=>'say "hi"'}),       '"say \"hi\""', 'tojson: quotes escaped');

###############################################################################
# list
###############################################################################

# ok 125-127
is(r('{{ x|list|join(",") }}', {x=>['a','b']}), 'a,b', 'list: already a list');
is(r('{{ x|list|first }}',     {x=>'scalar'}),  'scalar', 'list: wraps scalar');
is(r('{{ x|list|length }}',    {x=>[]}),        '0',    'list: empty list');

###############################################################################
# Filter pipeline chaining
###############################################################################

# ok 128-133
is(r('{{ x|upper|trim }}',   {x=>' hi '}), 'HI', 'pipeline: upper|trim');
is(r('{{ x|trim|upper }}',   {x=>' hi '}), 'HI', 'pipeline: trim|upper');
is(r('{{ x|sort|first }}',   {x=>['c','a','b']}), 'a', 'pipeline: sort|first');
is(r('{{ x|sort|last }}',    {x=>['c','a','b']}), 'c', 'pipeline: sort|last');
is(r('{{ x|join(",")|upper }}',{x=>['a','b','c']}), 'A,B,C', 'pipeline: join|upper');
is(r('{{ x|sort|reverse|first }}', {x=>['c','a','b']}), 'c', 'pipeline: sort|reverse|first');

###############################################################################
# add_filter custom filter
###############################################################################

# ok 134-137
{
    my $t = HP::Handy->new(auto_escape=>0);
    $t->add_filter('double', sub { $_[0] . $_[0] });
    is($t->render_string('{{ x|double }}', {x=>'ab'}), 'abab', 'custom filter: double');
    is($t->render_string('{{ x|double|upper }}', {x=>'ab'}), 'ABAB', 'custom filter in pipeline');
}
{
    my $t = HP::Handy->new(auto_escape=>0);
    $t->add_filter('prefix', sub { $_[1] . $_[0] });
    is($t->render_string('{{ x|prefix(">>") }}', {x=>'msg'}), '>>msg', 'custom filter with arg');
    is($t->render_string('{{ x|prefix(y) }}', {x=>'msg', y=>'<<'}), '<<msg', 'custom filter arg from var');
}

###############################################################################
# Filter on undefined values -- should not die
###############################################################################

# ok 138-141
is(r('{{ x|upper }}',        {}), '',   'upper on undef: empty string');
is(r('{{ x|length }}',       {}), '0',  'length on undef: 0');
is(r('{{ x|default("ok") }}',{}), 'ok', 'default on undef: fallback');
is(r('{{ x|trim }}',         {}), '',   'trim on undef: empty string');

END { print "# $PASS passed, $FAIL failed\n"; exit($FAIL ? 1 : 0) }
