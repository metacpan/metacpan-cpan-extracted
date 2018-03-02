use Test::More;

my $class  = 'Distribution::Cooker';

subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

subtest do_it => sub {
	my $cooker = $class->new;
	isa_ok( $cooker, $class );
	can_ok( $cooker, 'new' );
	};

done_testing();
