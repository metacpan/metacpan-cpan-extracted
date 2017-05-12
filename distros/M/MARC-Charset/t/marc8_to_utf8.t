use Test::More qw(no_plan);
use Unicode::Normalize;
use strict;
use warnings;

sub entityize {
	my $stuff = NFC(shift());
	$stuff =~ s/([\x{0080}-\x{fffd}])/sprintf('&#x%X;',ord($1))/sgoe;
	return $stuff;
}

use MARC::Charset qw(marc8_to_utf8 utf8_to_marc8);
is( entityize(marc8_to_utf8('fotografâias')), 'fotograf&#xED;as' , 'marc8_to_utf8');

