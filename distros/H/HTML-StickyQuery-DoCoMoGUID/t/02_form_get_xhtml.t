use strict;
use warnings;
use Test::Base;

plan tests => 1 * blocks;
run_compare input => 'expected';

use HTML::StickyQuery::DoCoMoGUID;

sub filter {
    my $html = shift;
    my $guid = HTML::StickyQuery::DoCoMoGUID->new;
    $guid->sticky( scalarref => \$html, xhtml => 0 );
}

__END__
===
--- input filter chomp
<form action="foo.cgi">
<input name="bar">
</form>
--- expected chomp
<form action="foo.cgi"><input type="hidden" name="guid" value="ON">
<input name="bar">
</form>
===
--- input filter chomp
<form action="foo.cgi" method="get">
<input name="bar" />
</form>
--- expected chomp
<form action="foo.cgi" method="get"><input type="hidden" name="guid" value="ON">
<input name="bar" />
</form>
===
--- input filter chomp
<form action="foo.cgi" method="GET">
<input name="bar" />
</form>
--- expected chomp
<form action="foo.cgi" method="GET"><input type="hidden" name="guid" value="ON">
<input name="bar" />
</form>
===
--- input filter chomp
<form action="foo.cgi?foo=bar">
<input name="bar">
</form>
--- expected chomp
<form action="foo.cgi?foo=bar"><input type="hidden" name="guid" value="ON">
<input name="bar">
</form>
===
--- input filter chomp
<form action="foo.cgi?foo=bar" method="get">
<input name="bar" />
</form>
--- expected chomp
<form action="foo.cgi?foo=bar" method="get"><input type="hidden" name="guid" value="ON">
<input name="bar" />
</form>
===
--- input filter chomp
<form action="http://example.com/foo.cgi">
<input name="bar">
</form>
--- expected chomp
<form action="http://example.com/foo.cgi">
<input name="bar">
</form>
===
--- input filter chomp
<form action="http://example.com/foo.cgi" method="get">
<input name="bar">
</form>
--- expected chomp
<form action="http://example.com/foo.cgi" method="get">
<input name="bar">
</form>
===
--- input filter chomp
<form action="#opps" method="get">
<input name="bar">
</form>
--- expected chomp
<form action="#opps" method="get">
<input name="bar">
</form>
