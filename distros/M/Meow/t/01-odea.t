use Test::More;
{
	package Foo;

	use Meow;
	use Basic::Types::XS qw/Num Str/;

	rw thing => Num;

	rw other => Str;
}

my $foo = Foo->new({ thing => 123, other => 'def' });

is($foo->thing, 123);
is($foo->other, 'def');
is($foo->thing(100), 100);
is($foo->thing, 100);
is($foo->other('abc'), 'abc');

my $foo = Foo->new( thing => 123, other => 'def' );

is($foo->thing, 123);
is($foo->other, 'def');

eval {
	Foo->new( thing => "abc", other => "def" );
};


like($@, qr/value did not pass type constraint "Num"/);

eval { 
	$foo->thing({ a => 1 });
};

like($@, qr/value did not pass type constraint "Num"/);

done_testing();

=pod
{
	package Foo;

	use Meow;
	use Basic::Types::XS qw/Num/;

	rw one => Coerce(
		Default(Num, 100),
		sub { return $_[1] }
	);

	method two => [Default(Num, 500)] => sub {
		return $_[1];
	};
}

my $foo = Foo->new();

is($foo->one, 100);
is($foo->two, 500);
=cut
