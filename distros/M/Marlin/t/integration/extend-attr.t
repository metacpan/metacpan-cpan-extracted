use Test2::V0;
use Data::Dumper;

{
	package Local::Foo;
	use Marlin
		foo => { default => 10, handles_via => 'Number', handles => { foo_eq => 'eq' } };
}

{
	package Local::Bar;
	use Marlin
		-base  => 'Local::Foo',
		bar    => { default => 11 },
		foo    => { default => 12, extends => 1, handles => { foo_eq => 'ge', foo_lt => 'lt' } },
		bar    => { default => 13, extends => 1 },
		'+bar' => { default => 14 };
}

my $x = Local::Bar->new;
is( $x->foo, 12 );
is( $x->bar, 14 );

{
	package Local::MyRole;
	use Marlin::Role foo => { reader => 'get_foo' };
}

{
	package Local::MyClass;
	use Marlin -with => 'Local::MyRole', foo => { writer => 'set_foo', extends => 1 };
}

my $y = Local::MyClass->new;
$y->set_foo( 42 );
is( $y->get_foo, 42 );

done_testing;
