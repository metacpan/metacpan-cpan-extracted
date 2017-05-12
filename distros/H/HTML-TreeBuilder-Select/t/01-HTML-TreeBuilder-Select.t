#!perl -T

use strict;
use warnings;

use Test::More (1 ? (tests => 7) : 'no_plan');

use HTML::TreeBuilder::Select;

my $tree = HTML::TreeBuilder->new;
$tree->parse_content(<<_END_);
<html>
<head></head>
<body>

<div id=1>

<ul class="c">
<li class="a">Entry 1</li>
<li class="a">Entry 2</li>
<li class="b">Empty</li>
<li class="a">Entry 3</li>
</ul>

<ul class="d">
<li class="a">Empty</li>
<li class="a">Entry 80</li>
<li>Entry 81</li>
</ul>

</div>

</body>
</html>
_END_

my @elements = $tree->select("div#1 ul.c li.a");
cmp_ok(scalar @elements, "==", 3);

cmp_ok($elements[0]->as_text, "eq", "Entry 1");
cmp_ok($elements[1]->as_text, "eq", "Entry 2");
cmp_ok($elements[2]->as_text, "eq", "Entry 3");

@elements = $tree->select("div#1 ul.d li");
cmp_ok($elements[0]->as_text, "eq", "Empty");
cmp_ok($elements[1]->as_text, "eq", "Entry 80");
cmp_ok($elements[2]->as_text, "eq", "Entry 81");
