use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

is(convert("<div>\n<title>\n</div>"), "<div>\n<title>\n</div>", 'html_block_no_disallowed_tag');
is(convert("foo <title> bar"), "<p>foo <title> bar</p>\n", 'inline_html_no_disallowed_tag');

is(convert("<div>\n<title>\n</div>", disallowed_html_tags => [qw(foo title)]), "<div>\n&lt;title>\n</div>", 'html_block_disallowed_tag');
is(convert("foo <title> bar", disallowed_html_tags => [qw(foo title)]), "<p>foo &lt;title> bar</p>\n", 'inline_html_disallowed_tag');

is(convert("<div>\n<title>\n</div>", disallowed_html_tags => "foo,title"), "<div>\n&lt;title>\n</div>", 'html_block_disallowed_tag_from_string');
is(convert("foo <title> bar", disallowed_html_tags => "foo,title"), "<p>foo &lt;title> bar</p>\n", 'inline_html_disallowed_tag_from_string');

is(convert("foo <title> bar <xmp> baz", disallowed_html_tags => [qw(title xmp)]), "<p>foo &lt;title> bar &lt;xmp> baz</p>\n", 'multiple_disallowed_tags');
is(convert("foo <TITLE> bar", disallowed_html_tags => [qw(title)]), "<p>foo &lt;TITLE> bar</p>\n", 'upper_case_tags_are_disallowed');

done_testing;
