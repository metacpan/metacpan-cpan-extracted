use Test::More tests => 27;

foreach my $class ( qw(Digest::CMAC Digest::OMAC1 Digest::OMAC2) ) {
	use_ok($class);
	can_ok( $class, 'new');
	can_ok( $class, 'add');
	can_ok( $class, 'digest');
	can_ok( $class, 'reset');
	can_ok( $class, 'hexdigest');
	can_ok( $class, 'b64digest');
	can_ok( $class, 'addfile');
	can_ok( $class, 'add_bits');
}
