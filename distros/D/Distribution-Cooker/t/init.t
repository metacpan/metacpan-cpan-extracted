use Test::More;

my $class  = 'Distribution::Cooker';
my $module = 'Foo::Bar';

subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'init' );
	};

subtest do_it => sub {
	my $cooker = $class->new;
	isa_ok( $cooker, $class );

	ok( $cooker->init, "init returns true" );
	};

done_testing();
