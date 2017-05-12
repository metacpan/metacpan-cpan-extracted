BEGIN { @classes = qw(Mac::PropertyList Mac::PropertyList::ReadBinary) }

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	print "bail out! $class did not compile\n" unless use_ok( $class );
	}
