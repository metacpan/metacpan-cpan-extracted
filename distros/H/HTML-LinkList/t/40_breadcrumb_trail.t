# testing dir_tree
use strict;
use Test::More tests => 4;

use HTML::LinkList qw(breadcrumb_trail);

my @links = qw(
/foo/bar/baz.html
/foo/bar/thing.html
/foo/wibble.html
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
# default
$link_html = breadcrumb_trail(labels=>\%labels,
    current_url=>'/foo/bar/baz.html');
ok($link_html, "(1) default; links HTML");

my $ok_str = '';
$ok_str = '<p><a href="/">Home</a> &gt; <a href="/foo/">Foo</a> &gt; <a href="/foo/bar/">Bar</a> &gt; <em>Bazzy</em>
</p>';

is($link_html, $ok_str, "(1) default; values match");

# root
$link_html = breadcrumb_trail(labels=>\%labels,
    current_url=>'/index.html');
ok($link_html, "(2) root; links HTML");

$ok_str = '<p><em>Home</em>
</p>';

is($link_html, $ok_str, "(2) root; values match");

