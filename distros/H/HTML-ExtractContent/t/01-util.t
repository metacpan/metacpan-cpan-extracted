use strict;
use warnings;
use Test::More tests => 10;
use HTML::ExtractContent::Util;

# strip
is(strip(""), ""); # empty
is(strip(" \t\r\nfoo"), "foo"); # left
is(strip("bar \t \r \n"), "bar"); # right
is(strip("  \t\r hoge\t\t\r\n"), "hoge"); # both

# strip_tags
is(strip_tags("url: <a href=\"http://example.com/\">http://example.com/</a>"),
   "url: http://example.com/");
is(strip_tags("<div>\n  <p>hoge foo.</p>\n  <p>bar tarao.</p>\n</div>"),
   "\n  hoge foo.\n  bar tarao.\n");

# eliminate_tags
is(eliminate_tags("url: <a href=\"http://example.com/\">http://example.com/</a>", 'a'),
   "url: ");
is(eliminate_tags("<div>\n  <p>hoge foo.</p>\n  <p>bar tarao.</p>\n</div>", 'p'),
   "<div>\n  \n  \n</div>");

# eliminate_links
is(eliminate_links("url: <a href=\"http://example.com/\">http://example.com/</a>"),
   "url: ");
is(eliminate_links("<div>\n  <p>hoge foo.</p>\n  <p>bar tarao.</p>\n</div>"),
   "<div>\n  <p>hoge foo.</p>\n  <p>bar tarao.</p>\n</div>");

