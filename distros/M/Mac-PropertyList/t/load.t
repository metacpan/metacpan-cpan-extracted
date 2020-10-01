BEGIN { @classes = qw(
	Mac::PropertyList
	Mac::PropertyList::ReadBinary
	Mac::PropertyList::WriteBinary
	) }

use Test::More tests => scalar @classes;

foreach my $class ( @classes ) {
	BAIL_OUT( "$class did not compile\n" ) unless use_ok( $class );
	}
