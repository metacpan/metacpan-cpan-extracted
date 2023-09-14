use Test2::V0;
use Test2::Require::Module 'Business::ISBN' => '3.007';

# this test is adapted from the one in the Business::ISBN testsuite
use GD::Barcode::EAN13;

ok( defined &Business::ISBN::png_barcode, "Method defined" );

foreach my $num ( qw( 0596527241 9780596527242 ) ) {
	my $isbn = Business::ISBN->new( $num );
	isa_ok( $isbn, 'Business::ISBN' );

	ok( $isbn->is_valid, "Valid ISBN" );

	my $png  = eval { $isbn->png_barcode };
	my $at = $@;
	ok( defined $png, "PNG defined for $num" );
	diag( "Eval error for $num: $at" ) if length $at;
}

done_testing();
