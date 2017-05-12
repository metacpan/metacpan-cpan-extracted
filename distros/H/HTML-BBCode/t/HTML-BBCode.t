#########################

use Test::More tests => 24;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;
use warnings;

my $bbc = HTML::BBCode->new();
isa_ok($bbc, 'HTML::BBCode', 'default');

# Basic parsing
is($bbc->parse('[b]foo[/b]'), '<span style="font-weight:bold">foo</span>', 'bold');
is($bbc->parse('[u]foo[/u]'), '<span style="text-decoration:underline">foo</span>', 'underline');
is($bbc->parse('[i]foo[/i]'), '<span style="font-style:italic">foo</span>', 'italic');
is($bbc->parse('[color=red]foo[/color]'), '<span style="color:red">foo</span>', 'color');
is($bbc->parse('[size=24]foo[/size]'),  '<span style="font-size:24px">foo</span>', 'font size');
is($bbc->parse('[quote]foo[/quote]'), '<div class="bbcode_quote_header">Quote:</div><div class="bbcode_quote_body">foo</div>', 'quote (simple)');
is($bbc->parse('[quote="foo"]bar[/quote]'), '<div class="bbcode_quote_header">&quot;foo&quot; wrote:</div><div class="bbcode_quote_body">bar</div>', 'quote (with author)');
is($bbc->parse('[code]<foo>[/code]'), '<div class="bbcode_code_header">Code:</div><div class="bbcode_code_body">&lt;foo&gt;</div>', 'code');
is($bbc->parse('[url]http://www.b10m.net/[/url]'), '<a href="http://www.b10m.net/">http://www.b10m.net/</a>', 'hyperlink (simple)');
is($bbc->parse('[url=http://www.b10m.net/]lame site[/url]'), '<a href="http://www.b10m.net/">lame site</a>', 'hyperlink (with link-text)');
is($bbc->parse('[email]foo@bar.com[/email]'), '<a href="mailto:foo@bar.com">foo@bar.com</a>', 'mailto-links');
is($bbc->parse('[img]foo.png[/img]'), '<img alt="" src="foo.png" />', 'image');
is($bbc->parse('[url=http://b10m.net][img]/b10m/logo.png.noway[/img][/url]'), '<a href="http://b10m.net"><img alt="" src="/b10m/logo.png.noway" /></a>', 'linked image');
is($bbc->parse('[list][*]foo[*]bar[/list]'), "<ul><li>foo</li>\n<li>bar</li>\n</ul>", 'unordered list');
is($bbc->parse('[list=1][*]foo[*]bar[/list]'), "<ol><li>foo</li>\n<li>bar</li>\n</ol>", 'ordered list');
is($bbc->parse('[list=a][*]foo[*]bar[/list]'), "<ol style=\"list-style-type:lower-alpha\"><li>foo</li>\n<li>bar</li>\n</ol>", 'ordered list (alpha style)');

# Mix them and do 'em wrong!
is($bbc->parse('[b]bold, [i]bold and italic[/i][/b][/b]'), '<span style="font-weight:bold">bold,  <span style="font-style:italic">bold and italic</span></span>[/b]', 'mixed, and "wrong"');

# Nested quotes
is($bbc->parse('[quote="world population"][quote="B10m"]no one listens[/quote]you\'ve got that right[/quote]boohoo'), '<div class="bbcode_quote_header">&quot;world population&quot; wrote:</div><div class="bbcode_quote_body"><div class="bbcode_quote_header">&quot;B10m&quot; wrote:</div><div class="bbcode_quote_body">no one listens</div> you&#39;ve got that right</div>boohoo', 'nested quotes');

# new object, with no_html
$bbc = HTML::BBCode->new({ no_html => 1 });
isa_ok($bbc, 'HTML::BBCode', 'default');
is($bbc->parse('<i>[b]bold[/b]</i>'), '&lt;i&gt;<span style="font-weight:bold">bold</span>&lt;/i&gt;', 'no_html');

# new object, with linebreak
$bbc = HTML::BBCode->new({ linebreaks => 1 });
isa_ok($bbc, 'HTML::BBCode', 'default');
my $test=<<'__TEXT__';
This is a test to see
wheter linebreaks can be converted.
__TEXT__

is($bbc->parse($test), "This is a test to see<br />\nwheter linebreaks can be converted.<br />\n", 'linebreaks');
