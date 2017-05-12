use Test::More tests => 4;
use HTML::Stream qw(:funcs);



# Test the 'un' methods.
my $text = "This <i>isn't</i> &quot;fun&quot;...";    
is(html_unmarkup($text), "This isn't &quot;fun&quot;...", "HTML Unmarkup");
is(html_unescape($text), 'This isn\'t "fun"...', "HTML Unescape");

# Test escaping.
is(html_escape("<>&"), "&lt;&gt;&amp;", "Escaping text");

# Test HTML.
is(html_tag(TR, NOWRAP=>undef), "<TR NOWRAP>", "HTML 1");