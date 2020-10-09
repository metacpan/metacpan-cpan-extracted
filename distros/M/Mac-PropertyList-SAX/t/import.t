# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::SAX (by kulp)

use Test::More 'no_plan';

require_ok( 'Mac::PropertyList::SAX' );

ok( ! defined( &parse_plist ), "parse_plist is not defined yet" );
my $result = Mac::PropertyList::SAX->import( 'parse_plist' );
ok( defined( &parse_plist ), "parse_plist is now defined" );


foreach my $name ( @Mac::PropertyList::EXPORT_OK )
	{
	next if $name eq 'parse_plist';
	ok( ! defined( &$name ), "$name is not defined yet" );
	}
	
Mac::PropertyList::SAX->import( ":all" );

foreach my $name ( @Mac::PropertyList::EXPORT_OK )
	{
	ok( defined( &$name ), "$name is now defined" );
	}

