use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Test2::V0;

sub run {
  &Markdown::Perl::convert;
}

is(run("[foo][bar]\n\n[bar]: /url"), "<p><a href=\"/url\">foo</a></p>\n", 'one_reference_link');
is(run("[foo][bar]\n\n[bar]: /url 'the title'"), "<p><a href=\"/url\" title=\"the title\">foo</a></p>\n", 'one_reference_link_with_title');

is(run("[foo][]\n\n[foo]: /url"), "<p><a href=\"/url\">foo</a></p>\n", 'collapsed_reference_link');
is(run("[foo]\n\n[foo]: /url"), "<p><a href=\"/url\">foo</a></p>\n", 'shortcut_reference_link');

is(run("[foo][bar\n\n[foo]: /url"), "<p><a href=\"/url\">foo</a>[bar</p>\n", 'shortcut_from_broken_reference');
is(run("[foo](not a link)\n\n[foo]: /url"), "<p><a href=\"/url\">foo</a>(not a link)</p>\n", 'shortcut_from_broken_inline');
is(run("[foo][bar]\n\n[foo]: /url"), "<p>[foo][bar]</p>\n", 'no_shortcut_from_missing_reference');

done_testing;
