#########################

use Test::More tests => 3;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $bbc = new HTML::BBCode;
isa_ok($bbc, 'HTML::BBCode');

my $text = "[list] [*]Test 1 [*]Test 2 (hint) [*]Test 3 [/list]";
is($bbc->parse($text), "<ul>  <li>Test 1</li>\n<li>Test 2 (hint)</li>\n<li>Test 3</li>\n</ul>");
