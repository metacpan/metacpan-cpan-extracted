use Test::More tests=>16;

use HTML::DublinCore;

my $html;
{
	open( FILE, 't/test.html' );
	local $/;
	$html = <FILE>;
	close( FILE );
}

my $dc = HTML::DublinCore->new( $html );

my $title = $dc->title();
isa_ok( $title, 'DublinCore::Element' );
like( $title->content(), qr/ motores /, 'retrieved single element' );

my @creators = $dc->creator();
is( scalar(@creators), 2, 'retrieved multiple elements' );

is( length( $dc->asHtml() ), 1861, 'asHtml() seems to work' );

is( scalar( $dc->elements() ), 8, 'elements()' );
foreach ( $dc->elements() ) {
    isa_ok( $_, 'DublinCore::Element' );
}

$title = $dc->element( 'Title' );
isa_ok( $title, 'DublinCore::Element', 'element() in scalar context' );

@creators = $dc->element( 'Creator' );
is( scalar(@creators), 2, 'element() in list context' );

my $date = $dc->element( 'Date.created' );
isa_ok( $date, 'DublinCore::Element', 'element() with qualified DC' );

