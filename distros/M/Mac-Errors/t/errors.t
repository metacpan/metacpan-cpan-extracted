use Test::More tests => 25;
use Mac::Errors qw(%MacErrors);

is( Mac::Errors::openErr(), -23, 'openErr has right value' );

my @triads = (
	[ qw( -34  dskFulErr ), 'disk full' ],
	[ qw( -185 badExtResource), 'extended resource has a bad format.' ],
	[ qw( -145 noMemForPictPlaybackErr noMemForPictPlaybackErr), ],
	[ qw( -147 rgnTooBigError rgnTooBigError), ],
	);
	
foreach my $triad ( @triads )
	{
	
	my $error_by_string = $MacErrors{ $triad->[0] };
	my $error_by_num    = $MacErrors{ $triad->[1] };
	
	is( $error_by_string->description, $triad->[2], 
		"Description for error by symbol is right" );
	
	is( $error_by_num->description, $triad->[2], 
		"Description for error by number is right" );

	is( $error_by_string->symbol, $triad->[1], 
		"Symbol for error by symbol is right" );
	
	is( $error_by_num->symbol, $triad->[1], 
		"Symbol for error by number is right" );

	is( $error_by_string->number, $triad->[0], 
		"Number for error by symbol is right" );
	
	is( $error_by_num->number, $triad->[0], 
		"Number for error by number is right" );
	}
