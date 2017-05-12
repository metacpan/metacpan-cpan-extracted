use Test::More tests => 10;

BEGIN {
	use_ok( 'MARC::Crosswalk::DublinCore' );
}

use strict;
use MARC::File::USMARC;

my $crosswalk = MARC::Crosswalk::DublinCore->new;

isa_ok( $crosswalk, 'MARC::Crosswalk::DublinCore' );
ok( !$crosswalk->qualified, 'DC simple' );

my $dc = $crosswalk->as_dublincore( MARC::File::USMARC->in( 't/camel.usmarc' )->next );

my $record = {
	subject     => [
		'Active server pages.',
		'ActiveX.',
		'Perl (Computer program language)'
	],
	type        => [ 'Text' ],
	description => [ '"Wiley Computer Publishing."' ],
	creator     => [ 'Martinsson, Tobias, 1976-' ],
	publisher   => [ 'New York : John Wiley & Sons,' ],
	language    => [ 'eng' ],
	title       => [ 'ActivePerl with ASP and ADO / Tobias Martinsson.' ]
};

foreach my $element ( keys %$record ) {
	my @elements = $dc->$element;
	is_deeply( [ sort map { $_->content } @elements ], $record->{ $element }, $element );
}