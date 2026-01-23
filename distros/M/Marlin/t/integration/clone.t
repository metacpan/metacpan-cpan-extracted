use Test2::V0;

my $GOT = '';

{
	package Local::Foo;
	use Marlin foo => {
		clone        => 'mkclone',
		handles_via  => 'Array',
		handles      => { add_foo => 'push' },
		clone_bypass => 'my _ref_foo',
	};
	sub mkclone {
		my ( $self, $attr, $value ) = @_;
		$GOT .= $attr;
		return Class::XSConstructor::clone( $value );
	}
	sub _get_foo {
		_ref_foo( @_ );
	}
}

my @arr = ( 1, 2, 3 );
my $foo = Local::Foo->new( foo => \@arr );

push @arr, 4;
is( $foo->foo, [ 1, 2, 3 ] );

push @{ $foo->foo }, 4;
is( $foo->foo, [ 1, 2, 3 ] );

is( $GOT, 'foo'x4 );

$foo->add_foo( 4 );

is( $foo->foo, [ 1, 2, 3, 4 ] );

is( $GOT, 'foo'x5 );

push @{ $foo->_get_foo }, 5;

is( $GOT, 'foo'x5 );

is( $foo->foo, [ 1, 2, 3, 4, 5 ] );

is( $GOT, 'foo'x6 );

ok !$foo->can('_ref_foo');

done_testing;