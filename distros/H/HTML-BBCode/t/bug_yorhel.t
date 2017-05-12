#########################

use Test::More tests => 4;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $bbc = new HTML::BBCode({
  no_html => 1,
  linebreaks => 1 });
isa_ok($bbc, 'HTML::BBCode', 'default');

my $text="[code]\n[u]some code[/u]\n[/code]";
my $result='<div class="bbcode_code_header">Code:</div><div class="bbcode_code_body"><br />&nbsp;[u]&nbsp;some&nbsp;code&nbsp;[/u]&nbsp;<br /></div>';

is($bbc->parse($text), $result, "Tags in code");

$text="[list]\n[*]Red\n[*]Blue\n[*]Yellow\n[/list]";
$result="<ul>\n<li>Red</li>\n<li>Blue</li>\n<li>Yellow</li>\n</ul>";

is($bbc->parse($text), $result, "Tags in code");
