use Test::More;

my $class = 'Distribution::Cooker';
my $dist  = 'Foo-Bar';

subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'dist' );
	};

subtest do_it => sub {
	my $cooker = $class->new;
	isa_ok( $cooker, $class );

	ok( ! defined $cooker->dist, "There is nothing in dist at start" );
	is( $cooker->dist( $dist ), $dist, "Set dist and return it" );
	is( $cooker->dist, $dist, "Remembers dist name" );
	};

done_testing();
