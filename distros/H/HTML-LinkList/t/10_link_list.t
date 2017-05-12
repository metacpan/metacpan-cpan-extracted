# testing link_list
use strict;
use Test::More tests => 6;

use HTML::LinkList qw(link_list);

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

my $link_html = '';
# default, no current
$link_html = link_list(labels=>\%labels,
    urls=>\@links);
ok($link_html, "(1) default; links HTML");

my $ok_str = '';
$ok_str = '<ul><li><a href="/foo/bar/baz.html">Bazzy</a></li>
<li><a href="/fooish.html">Fooish</a></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul>';

is($link_html, $ok_str, "(1) default; values match");

# default format with current
$link_html = link_list(labels=>\%labels,
    urls=>\@links,
    current_url=>'/fooish.html');
ok($link_html, "(2) default with current; links HTML");

$ok_str = '<ul><li><a href="/foo/bar/baz.html">Bazzy</a></li>
<li><em>Fooish</em></li>
<li><a href="/bringle/">Bringle</a></li>
<li><a href="/tray/nav.html">Navigation</a></li>
<li><a href="/tray/tea_tray.html">Tea Tray</a></li>
</ul>';

is($link_html, $ok_str, "(2) default with current; values match");

# para, no current
$link_html = link_list(labels=>\%labels,
    urls=>\@links,
    links_head=>'<p>',
    links_foot=>'</p>',
    pre_item=>'',
    post_item=>'',
    item_sep=>' :: ');
ok($link_html, "(3) para; links HTML");

$ok_str = '<p><a href="/foo/bar/baz.html">Bazzy</a> :: <a href="/fooish.html">Fooish</a> :: <a href="/bringle/">Bringle</a> :: <a href="/tray/nav.html">Navigation</a> :: <a href="/tray/tea_tray.html">Tea Tray</a></p>';

is($link_html, $ok_str, "(3) para; values match");

