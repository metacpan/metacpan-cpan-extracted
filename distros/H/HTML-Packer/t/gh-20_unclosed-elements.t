#!perl

use strict;
use warnings;

use Test::More;
use Time::HiRes qw(time);

use HTML::Packer;

my $packer = HTML::Packer->init;

# An unclosed element was searched for its closing tag to the end of the
# document, once for each such element: quadratic time
foreach my $tag ( qw(pre code textarea script style) ) {
    my $html = '<html><body>' . ( "<$tag>a " x 20_000 ) . '</body></html>';
    my $start = time;
    $packer->minify( \$html, { remove_comments => 1 } );
    cmp_ok( time - $start, '<', 2, "20000 unclosed <$tag> elements are packed quickly" );
}

# Closed elements are unchanged by the fix
my $html = "<html><body>\n  <p>a   b</p>\n  <pre>  keep\n   this  </pre>\n</body></html>";
$packer->minify( \$html, {} );
like( $html, qr{<pre>  keep\n   this  </pre>}, 'a closed <pre> is kept as it is' );
like( $html, qr{<p>a b</p>}, 'and the rest is still packed' );

# An unclosed element takes the rest of the document, which is left alone
$html = "<html><body>\n  <p>a   b</p>\n  <pre>  keep\n  <p>c   d</p>\n</body></html>";
$packer->minify( \$html, {} );
like( $html, qr{<p>a b</p>}, 'what comes before an unclosed <pre> is packed' );
like( $html, qr{<pre>  keep\n  <p>c   d</p>\n</body></html>}, 'what comes after it is kept as it is' );

# The JavaScript packer is not given the rest of the HTML
SKIP: {
    skip 'JavaScript::Packer is not installed', 1 unless eval { require JavaScript::Packer; 1 };
    $html = qq{<html><body><script type="text/javascript">var x = 1;\n<p>text   here</p></body></html>};
    $packer->minify( \$html, { do_javascript => 'best' } );
    like( $html, qr{<p>text   here</p></body></html>}, 'the HTML after an unclosed <script> is not given to the JavaScript packer' );
}

done_testing();
