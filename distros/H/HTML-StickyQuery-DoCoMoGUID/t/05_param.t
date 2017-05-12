use strict;
use warnings;
use Test::Base;

plan tests => 1 * blocks;
run_compare input => 'expected';

use HTML::StickyQuery::DoCoMoGUID;

sub filter {
    my $html = shift;
    my $guid = HTML::StickyQuery::DoCoMoGUID->new;
    $guid->sticky( scalarref => \$html, param => { sessionid => 'SID' }, xhtml => 0 );
}

__END__
===
--- input filter chomp
<a href="/foo.html">foo</a>
--- expected chomp
<a href="/foo.html?guid=ON&amp;sessionid=SID">foo</a>
===
--- input filter chomp
<a href="/foo.html?foo=bar">foo</a>
--- expected chomp
<a href="/foo.html?guid=ON&amp;foo=bar&amp;sessionid=SID">foo</a>
===
--- input filter chomp
<form action="foo.cgi">
<input name="bar">
</form>
--- expected chomp
<form action="foo.cgi"><input type="hidden" name="guid" value="ON"><input type="hidden" name="sessionid" value="SID">
<input name="bar">
</form>
===
--- input filter chomp
<form action="foo.cgi" method="post">
<input name="bar">
</form>
--- expected chomp
<form action="foo.cgi?guid=ON" method="post"><input type="hidden" name="sessionid" value="SID">
<input name="bar">
</form>
