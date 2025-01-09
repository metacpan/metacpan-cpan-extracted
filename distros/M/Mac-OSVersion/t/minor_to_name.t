use Test::More;

my $class  = 'Mac::OSVersion';
my $method = 'minor_to_name';

subtest setup => sub {
	use_ok( $class );
	can_ok( $class, $method );
	};

subtest minor_arg => sub {
	diag( "You may see a warning here" );
	my $name = $class->$method( '4' );
	diag( "You shouldn't see a warning after this" );
	ok( defined $name, "Name is defined" );
	is( $name, 'Tiger', "Tiger is the right version" );
	};

subtest major_arg => sub {
	my $name = $class->$method( '4', '10' );
	ok( defined $name, "Name is defined" );
	is( $name, 'Tiger', "Tiger is the right version with explicit major version 10" );
	};

subtest macos => sub {
	my $name = $class->$method( '0', '11' );
	ok( defined $name, "Name is defined" );
	is( $name, 'Big Sur', "Big Sur is the right version with explicit major version 11" );
	};

subtest macos => sub {
	my $name = $class->$method( '0', '12' );
	ok( defined $name, "Name is defined" );
	is( $name, 'Monterey', "Monterey is the right version with explicit major version 12" );
	};

done_testing();
