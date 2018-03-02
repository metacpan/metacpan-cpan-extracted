use Test::More;

my $class  = 'Distribution::Cooker';
my $module = 'Foo::Bar';

subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'module' );
	};

subtest do_it => sub {
	my $cooker = $class->new;
	isa_ok( $cooker, $class );
	can_ok( $cooker, 'module' );

	ok( ! $cooker->module, "There is nothing in module at start" );
	is( $cooker->module( $module ), $module, "Set module and return it" );
	is( $cooker->module, $module, "Remembers module name" );
	};

done_testing();
