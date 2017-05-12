# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::XS (by kulp)

BEGIN { @classes = qw(Mac::PropertyList::XS) }

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	print "bail out! $class did not compile\n" unless use_ok( $class );
	}
