# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::XS (by kulp)
BEGIN { @plists = <plists/*.plist>; }

use Test::More;
eval "use Time::HiRes";

if( $@ ) { plan skip_all => "Needs Time::HiRes to time parsing" }
else     { plan tests => scalar @plists }

use Mac::PropertyList::XS;

my $debug = $ENV{PLIST_DEBUG} || 0;

foreach my $file ( @plists )
	{
	diag( "Working on $file" ) if $debug;
	unless( open FILE, $file )
		{
		fail( "Could not open $file" );
		}
		
	my $data = do { local $/; <FILE> };
	close FILE;

	my $b = length $data;

	my $time1 = [ Time::HiRes::gettimeofday() ];
	my $plist = Mac::PropertyList::XS::parse_plist( $data );
	my $time2 = [ Time::HiRes::gettimeofday() ];

	my $elapsed = Time::HiRes::tv_interval( $time1, $time2 );
	diag( "$file [$b bytes] parsed in $elapsed seconds" );

	isa_ok( $plist, 'HASH' );
	}
