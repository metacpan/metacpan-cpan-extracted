use Test::More tests => 12;

BEGIN {
	use_ok( 'MARC::Crosswalk::DublinCore' );
}

use strict;
use MARC::File::USMARC;

my $crosswalk = MARC::Crosswalk::DublinCore->new;

isa_ok( $crosswalk, 'MARC::Crosswalk::DublinCore' );

$crosswalk->qualified( 1 );

ok( $crosswalk->qualified, 'DC qualified' );

my $dc = $crosswalk->as_dublincore( MARC::File::USMARC->in( 't/camel.usmarc' )->next );

my $record = {
	format      => [
		{ content => 'xxi, 289 p. :', qualifier => 'Extent', scheme => undef }
	],
	subject     => [
		{ content => '005.13/3 21', scheme => 'DDC', qualifier => undef },
		{ content => 'Active server pages.', scheme => 'LCSH', qualifier => undef },
		{ content => 'ActiveX.', scheme => 'LCSH', qualifier => undef },
		{ content => 'Perl (Computer program language)', scheme => 'LCSH', qualifier => undef },
		{ content => 'QA76.73.P22 M33 2000', scheme => 'LCC', qualifier => undef },
	],
	type        => [
		{ content => 'Text', scheme => 'DCMI Type Vocabulary', qualifier => undef },
	],
	description => [
		{ content => '"Wiley Computer Publishing."', qualifier => undef, scheme => undef },
	],
	creator     => [
		{ content => 'Martinsson, Tobias, 1976-', qualifier => undef, scheme => undef },
	],
	date     => [
		{ content => '2000', qualifier => 'Issued', scheme => undef },
		{ content => '2000.', qualifier => 'Created', scheme => undef },
		{ content => '2000.', qualifier => 'Issued', scheme => undef },
	],
	publisher   => [
		{ content => 'New York : John Wiley & Sons,', qualifier => undef, scheme => undef },
	],
	language    => [
		{ content => 'eng', scheme => 'ISO 639-2', qualifier => undef },
	],
	title       => [
		{ content => 'ActivePerl with ASP and ADO / Tobias Martinsson.', qualifier => undef, scheme => undef },
	]
};

foreach my $element ( keys %$record ) {
	my @elements = sort { $a->content cmp $b->content || $a->qualifier cmp $b->qualifier || $a->scheme cmp $b->scheme } $dc->$element;
	my @result   = map +{ qualifier => $_->qualifier || undef, scheme => $_->scheme || undef, content => $_->content || undef }, @elements;
	is_deeply( \@result, $record->{ $element }, $element );
}