#########################

use Test::More tests => 7;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $bbc = new HTML::BBCode;
isa_ok($bbc, 'HTML::BBCode');

my $text = "[url=javascript:alert('B10m should check security better...')]click me[/url]";
is($bbc->parse($text), "&lt;a href=&quot;javascript:alert(&#39;B10m should check security better...&#39;)&quot;&gt;click me&lt;/a&gt;");

$text = "[img]javascript:alert('B10m thanks Alex')[/img]";
is($bbc->parse($text), '<img alt="" />');

$text = "But I can still use the link thing normally, like javascript:alert('ok'), right?";
is($bbc->parse($text), "But I can still use the link thing normally, like javascript:alert(&#39;ok&#39;), right?");

my $bbc2 = new HTML::BBCode({ no_jslink => 0 });
isa_ok($bbc2, 'HTML::BBCode');
$text = "[url=javascript:alert('No Fear!')]click me[/url]";
is($bbc2->parse($text), '&lt;a href=&quot;javascript:alert(&#39;No Fear!&#39;)&quot;&gt;click me&lt;/a&gt;');
