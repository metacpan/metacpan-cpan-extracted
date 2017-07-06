# Stolen from Mac::PropertyList (by bdfoy) for use in Mac::PropertyList::XS (by kulp)
BEGIN { @plists = glob( 'plists/*.plist' ); }

use Test::More;
eval "use Time::HiRes";

if( $@ ) { plan skip_all => "Needs Time::HiRes to time parsing" }
else     { plan tests => 2 * scalar @plists }

use Mac::PropertyList::XS;

my $debug = $ENV{PLIST_DEBUG} || 0;

foreach my $file ( @plists ) {
	diag( "Working on $file" ) if $debug;
	unless( open FILE, '<', $file ) {
		fail( "Could not open $file" );
		next;
		}

	my $data = do { local $/; <FILE> };
	close FILE;

	my $b = length $data;

	my $time1 = [ Time::HiRes::gettimeofday() ];
	my $plist = eval { Mac::PropertyList::XS::parse_plist( $data ) };
	my $error_at = $@;
	$error_at ?
		fail( "Error parsing $file: $error_at" )
			:
		pass( "Parsed $file without a problem" );

	my $time2 = [ Time::HiRes::gettimeofday() ];

	my $elapsed = Time::HiRes::tv_interval( $time1, $time2 );
	diag( "$file [$b bytes] parsed in $elapsed seconds" );

	# All of the test plists have a dict at the top level, except for binary2.
	isa_ok( $plist, ( $file eq 'plists/binary2.plist' ) ? 'ARRAY' : 'HASH' );
	}
