# testing full_tree
use strict;
use Test::More tests => 12;

use HTML::LinkList qw(full_tree);

my @links = qw(
/foo/bar/baz.html
/fooish.html
/bringle/
/tray/nav.html
/tray/tea_tray.html
);

my %labels = (
'/tray/nav.html' => 'Navigation',
'/foo/bar/baz.html' => 'Bazzy',
);
my $test_count = 0;

my $link_html = '';
# default, no current
$test_count++;
$link_html = full_tree(labels=>\%labels,
    paths=>\@links);
ok($link_html, "($test_count) default; links HTML");

my $ok_str = '';
$ok_str = '<ul><li><a href="/">Home</a>
<ul><li><a href="/bringle/">Bringle</a></li>
<li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a>
<ul><li><a href="/foo/bar/baz.html">Bazzy</a></li>
</ul></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/tray/">Tray</a>
<ul><li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul></li>
</ul></li>
</ul>';

is($link_html, $ok_str, "($test_count) default; values match");

# start_depth
$test_count++;
$link_html = full_tree(labels=>\%labels,
    paths=>\@links,
    start_depth=>1);
ok($link_html, "($test_count) start_depth=1; links HTML");

$ok_str = '<ul><li><a href="/bringle/">Bringle</a></li>
<li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a>
<ul><li><a href="/foo/bar/baz.html">Bazzy</a></li>
</ul></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/tray/">Tray</a>
<ul><li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul></li>
</ul>';

is($link_html, $ok_str, "($test_count) start_depth=1; values match");

# start_depth and end_depth
$test_count++;
$link_html = full_tree(labels=>\%labels,
    paths=>\@links,
    start_depth=>1,
    end_depth=>2);
ok($link_html, "($test_count) start_depth=1, end_depth=2; links HTML");

$ok_str = '<ul><li><a href="/bringle/">Bringle</a></li>
<li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/tray/">Tray</a>
<ul><li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul></li>
</ul>';

is($link_html, $ok_str, "($test_count) start_depth=1, end_depth=2; values match");

# preserve_order, no current
$test_count++;
$link_html = full_tree(labels=>\%labels,
    paths=>\@links,
    preserve_order=>1);
ok($link_html, "($test_count) preserve_order; links HTML");

$ok_str = '';
$ok_str = '<ul><li><a href="/">Home</a>
<ul><li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a>
<ul><li><a href="/foo/bar/baz.html">Bazzy</a></li>
</ul></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/">Tray</a>
<ul><li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul></li>
</ul></li>
</ul>';

is($link_html, $ok_str, "($test_count) preserve_order; values match");

# differing formats, no current
$test_count++;
my %formats = (
 '1' => {
 tree_head=>"<ol>",
 tree_foot=>"</ol>\n",
 },
 '2' => {
 pre_item=>'(',
 post_item=>')',
 item_sep=>",\n",
 tree_sep=>' -> ',
 tree_head=>"<br/>\n",
 tree_foot=>"",
 },
 '3' => {
 pre_item=>' {{ ',
 post_item=>' }} ',
 item_sep=>" ::\n",
 },
 );
$link_html = full_tree(labels=>\%labels,
    paths=>\@links,
    formats=>\%formats,
    preserve_order=>1);
ok($link_html, "($test_count) formats; links HTML");

$ok_str = '<ul><li><a href="/">Home</a>
<ol><li><a href="/foo/">Foo</a>
<br/>
(<a href="/foo/bar/">Bar</a> -> <br/>
 {{ <a href="/foo/bar/baz.html">Bazzy</a> }} )</li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/">Tray</a>
<br/>
(<a href="/tray/nav.html">Navigation</a>),
(<a href="/tray/tea_tray.html">Tea Tray</a>)</li></ol>
</li>
</ul>';

is($link_html, $ok_str, "($test_count) formats; values match");

# Mixed caps in links
$test_count++;
@links = qw(
/foo/bar/baz.html
/fooish.html
/bringle/
/tray/nav.html
/tray/tea_tray.html
/industry/TLA_foo.html
/industry/TLA_Bar.html
);
%labels = (
'/tray/nav.html' => 'Navigation',
);
$link_html = full_tree(labels=>\%labels,
    paths=>\@links);
ok($link_html, "($test_count) Mixed caps; links HTML");

$ok_str = 
'<ul><li><a href="/">Home</a>
<ul><li><a href="/bringle/">Bringle</a></li>
<li><a href="/foo/">Foo</a>
<ul><li><a href="/foo/bar/">Bar</a>
<ul><li><a href="/foo/bar/baz.html">Baz</a></li>
</ul></li>
</ul></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/industry/">Industry</a>
<ul><li><a href="/industry/TLA_Bar.html">TLA Bar</a></li>
<li><a href="/industry/TLA_foo.html">TLA Foo</a></li>
</ul></li>
<li><a href="/tray/">Tray</a>
<ul><li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul></li>
</ul></li>
</ul>';


is($link_html, $ok_str, "($test_count) Mixed caps; values match");
