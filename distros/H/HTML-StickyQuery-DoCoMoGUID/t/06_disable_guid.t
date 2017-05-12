use strict;
use warnings;
use Test::Base;

plan tests => 1 * blocks;
run_compare input => 'expected';

use HTML::StickyQuery::DoCoMoGUID;

sub filter {
    my $html = shift;
    my $guid = HTML::StickyQuery::DoCoMoGUID->new;
    $guid->sticky( scalarref => \$html, xhtml => 0, disable_guid => 1 );
}

__END__
===
--- input filter chomp
<a href="/foo.html">foo</a>
--- expected chomp
<a href="/foo.html">foo</a>
===
--- input filter chomp
<a href="/foo.html?foo=bar">foo</a>
--- expected chomp
<a href="/foo.html?foo=bar">foo</a>
===
--- input filter chomp
<form action="foo.cgi">
<input name="bar">
</form>
--- expected chomp
<form action="foo.cgi">
<input name="bar">
</form>
===
--- input filter chomp
<form action="foo.cgi" method="post">
<input name="bar">
</form>
--- expected chomp
<form action="foo.cgi" method="post">
<input name="bar">
</form>
