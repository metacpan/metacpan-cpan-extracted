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
<a href="/foo.html">foo</a>
--- expected chomp
<a href="/foo.html?guid=ON">foo</a>
===
--- input filter chomp
<a href="foo.html">foo</a>
--- expected chomp
<a href="foo.html?guid=ON">foo</a>
===
--- input filter chomp
<a href="../foo.html">foo</a>
--- expected chomp
<a href="../foo.html?guid=ON">foo</a>
===
--- input filter chomp
<a href="#bar">foo</a>
--- expected chomp
<a href="#bar">foo</a>
===
--- input filter chomp
<a href="http://example.com/">foo</a>
--- expected chomp
<a href="http://example.com/">foo</a>
