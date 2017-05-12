use strict;
use warnings;

use Test::More tests => 13;
use Mac::PropertyList qw(parse_plist_file parse_plist);


foreach my $string ( ( '', 'blirt', '<XML' ) ) {
	my $plist = eval { parse_plist( $string ) };
	my $at = $@;
	ok( length $at, '$@ has an error message' );
	like( $at, qr/doesn't look like a valid plist/, 
		'$@ has the right error message' );
	}

foreach my $file ( ( 'Makefile.PL', 'MANIFEST' ) ) {
	my $plist = eval { parse_plist_file( $file ) };
	my $at = $@;
	ok( length $at, '$@ has an error message' );
	like( $at, qr/doesn't look like a valid plist/, 
		'$@ has the right error message' );
	}

foreach my $file ( 'not_there' ) {
	my $plist = eval { parse_plist_file( $file ) };
	my $at = $@;
	ok( ! -e $file, "file [$file] is not there" );
	ok( length $at, '$@ has an error message' );
	like( $at, qr/does not exist/, 
		'$@ has the right error message' );
	}
