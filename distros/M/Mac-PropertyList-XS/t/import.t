# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::XS (by kulp)

use Test::More 'no_plan';

require_ok( 'Mac::PropertyList::XS' );

ok( ! defined( &parse_plist ), "parse_plist is not defined yet" );
my $result = Mac::PropertyList::XS->import( 'parse_plist' );
ok( defined( &parse_plist ), "parse_plist is now defined" );


foreach my $name ( @Mac::PropertyList::EXPORT_OK )
	{
	next if $name eq 'parse_plist';
	ok( ! defined( &$name ), "$name is not defined yet" );
	}
	
Mac::PropertyList::XS->import( ":all" );

foreach my $name ( @Mac::PropertyList::EXPORT_OK )
	{
	ok( defined( &$name ), "$name is now defined yet" );
	}

