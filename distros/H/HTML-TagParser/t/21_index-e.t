# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 10;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $FILE = "t/sample/index-e.html";
# ----------------------------------------------------------------
    &test_main();
# ----------------------------------------------------------------
sub test_main {
    my $html = HTML::TagParser->new( $FILE );
    ok( ref $html, "open by new()" );

    my $root = $html->getElementsByTagName('html');
    is( $root->getAttribute('lang'), 'en', 'html lang en' );

	my @meta = $html->getElementsByTagName('meta');
	my $css = (grep {$_->getAttribute('http-equiv') && $_->getAttribute('http-equiv') eq 'Content-Style-Type'} @meta)[0];
	is( $css->getAttribute('content'), 'text/css', 'Content-Style-Type' );

	my $copy = (grep {$_->getAttribute('name') && $_->getAttribute('name') eq 'copyright'} @meta)[0];
	like( $copy->getAttribute('content'), qr/^Copyright/i, 'copyright' );

	my @link = $html->getElementsByTagName('link');
	my $rss = (grep {$_->getAttribute('rel') eq 'alternate'} @link)[0];
	is( $rss->getAttribute('href'), 'http://www.kawa.net/rss/index-e.rdf', 'application/rss+xml' );

	my $style = $html->getElementsByAttribute('rel','stylesheet');
	is( $style->getAttribute('type'), 'text/css', 'link rel stylesheet' );

	my $script = $html->getElementsByAttribute('src','http://www.kawa.net/works/js/jkl/js/jkl-parsexml.js');
	is( $script->tagName(), 'script', 'script src' );

	my $table = $html->getElementsByTagName('table');
	is( $table->getAttribute('width'), '100%', 'first table' );

	my $address = $html->getElementsByTagName('address');
	like( $address->innerText, qr/Copyright/i, 'address' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
__END__
