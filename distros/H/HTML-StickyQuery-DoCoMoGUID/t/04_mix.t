use strict;
use warnings;
use Test::Base;

plan tests => 1 * blocks;
run_compare input => 'expected';

use HTML::StickyQuery::DoCoMoGUID;

sub filter {
    my $html = shift;
    my $guid = HTML::StickyQuery::DoCoMoGUID->new;
    $guid->sticky( scalarref => \$html );
}

__END__
===
--- input filter chomp
<form action="foo.cgi"><a href="/foo.html">foo</a>
<input name="bar">
</form>
<form action="foo.cgi" method="post">
<input name="bar" />
<a href="/foo.html">foo</a>
</form>
--- expected chomp
<form action="foo.cgi"><input type="hidden" name="guid" value="ON" /><a href="/foo.html?guid=ON">foo</a>
<input name="bar">
</form>
<form action="foo.cgi?guid=ON" method="post">
<input name="bar" />
<a href="/foo.html?guid=ON">foo</a>
</form>
===
--- input filter chomp
<form action="foo.cgi" method="POST">
<a href="../foo.html">foo</a>
<input name="bar" />
</form><form action="foo.cgi" method="GET">
<input name="bar" />
</form>
--- expected chomp
<form action="foo.cgi?guid=ON" method="POST">
<a href="../foo.html?guid=ON">foo</a>
<input name="bar" />
</form><form action="foo.cgi" method="GET"><input type="hidden" name="guid" value="ON" />
<input name="bar" />
</form>
===
--- input filter chomp
<form action="foo.cgi?foo=bar" method="post">
<a href="#bar">foo</a>
<input name="bar" />
</form>
--- expected chomp
<form action="foo.cgi?foo=bar&amp;guid=ON" method="post">
<a href="#bar">foo</a>
<input name="bar" />
</form>
===
--- input filter chomp
<a href="http://example.com/">foo</a>
<form action="http://example.com/foo.cgi" method="post">
<input name="bar">
</form>
--- expected chomp
<a href="http://example.com/">foo</a>
<form action="http://example.com/foo.cgi" method="post">
<input name="bar">
</form>
===
--- input filter chomp
<form action="#opps" method="post">
<input name="bar">
</form>
<a href="foo.html">foo</a>
--- expected chomp
<form action="#opps" method="post">
<input name="bar">
</form>
<a href="foo.html?guid=ON">foo</a>
