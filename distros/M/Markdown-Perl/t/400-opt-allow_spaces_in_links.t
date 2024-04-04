use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

is(convert("[foo] [bar]\n\n[bar]: /url"), "<p>[foo] <a href=\"/url\">bar</a></p>\n", 'none');
is(convert("[foo] [bar]\n\n[bar]: /url", allow_spaces_in_links => 'reference'), "<p><a href=\"/url\">foo</a></p>\n", 'reference');
is(convert("[foo]\n[bar]\n\n[bar]: /url"), "<p>[foo]\n<a href=\"/url\">bar</a></p>\n", 'none_with_newline');
is(convert("[foo]\n[bar]\n\n[bar]: /url", allow_spaces_in_links => 'reference'), "<p><a href=\"/url\">foo</a></p>\n", 'reference_with_newline');

done_testing;
