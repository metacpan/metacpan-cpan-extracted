{
	package Local::Foo1;
	use Marlin foo => {
		':Lvalue' => 1,
		alias     => [ qw/ FOO fool / ],
		alias_for => 'Lvalue',
	};
}

use Test2::V0;

my $o = Local::Foo1->new;

$o->foo = 42;
is( $o->foo, 42 );

$o->FOO = 43;
is( $o->FOO, 43 );

$o->fool = 44;
is( $o->fool, 44 );

done_testing;
