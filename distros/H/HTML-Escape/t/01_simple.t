use strict;
use warnings;
use utf8;
use Test::More;
use HTML::Escape;

ok(HTML::Escape::USE_XS, "uses XS module") or do {
    eval { XSLoader::load('HTML::Escape', $HTML::Escape::VERSION) };
    diag $@ if $@;
};
is(escape_html("<^o^>"), '&lt;^o^&gt;');
is(escape_html("'"), "&#39;");
is(escape_html("\0>"), "\0&gt;");
is(escape_html("`"), "&#96;");
is(escape_html("{}"), "&#123;&#125;");

done_testing;

