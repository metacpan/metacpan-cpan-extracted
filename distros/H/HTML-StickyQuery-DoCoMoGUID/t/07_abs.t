use strict;
use warnings;
use Test::Base;

plan tests => 1 * blocks;
run_compare input => 'expected';

use HTML::StickyQuery::DoCoMoGUID;

sub filter {
    my $html = shift;
    my $guid = HTML::StickyQuery::DoCoMoGUID->new(abs => 1);
    $guid->sticky( scalarref => \$html );
}

__END__
===
--- input filter chomp
<a href="http://example.com/foo.html">foo</a>
--- expected chomp
<a href="http://example.com/foo.html?guid=ON">foo</a>
===
--- input filter chomp
<form action="http://example.com/foo.cgi">
<input name="bar">
</form>
--- expected chomp
<form action="http://example.com/foo.cgi"><input type="hidden" name="guid" value="ON" />
<input name="bar">
</form>
