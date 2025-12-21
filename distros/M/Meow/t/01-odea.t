use Test::More;
{
	package Foo;

	use Basic::Types::XS qw/Num Str ArrayRef/;
	use Meow;

	ro only => Default(Num, sub { 100 });

	rw thing => Builder(Num, sub { $_[0]->only });

	sub modify { return qw/a b c d/; }

	rw other => Str;
	
	rw array => Trigger(
		Coerce(
			Default(ArrayRef, [1,2,3]), 
			sub { ref $_[0] eq 'ARRAY' ? $_[0] : [split /,/, $_[0]] }
		),
		sub { 1; }
	);
}

{
	package Zap;
	
	use Basic::Types::XS qw/Str/;
	use Meow;
	
	rw boo => Str;

	1;
}
	
{
	package Bar;

	use Meow;

	extends qw/Foo Zap/;

	1;
}


my $foo = Foo->new({ other => 'def' });

is($foo->thing, 100);
is($foo->only, 100);
is($foo->other, 'def');
is($foo->thing(200), 200);
is($foo->thing, 200);
is($foo->other('abc'), 'abc');
is_deeply($foo->array(), [1,2,3]);
is_deeply($foo->array('a,b,c'), [qw/a b c/]);
my $foo = Foo->new( thing => 123, other => 'def', array => [ 5, 6, 7 ] );

is_deeply([$foo->modify], [qw/a b c d/]);


is($foo->thing, 123);
is($foo->other, 'def');
is_deeply($foo->array(), [5, 6, 7]);
eval {
	Foo->new( thing => "abc", other => "def" );
};


like($@, qr/value did not pass type constraint "Num"/);

eval { 
	$foo->thing({ a => 1 });
};

like($@, qr/value did not pass type constraint "Num"/);

eval {
	$foo->only(500);
};

like($@, qr/Read only attributes cannot be set/);

my $bar = Bar->new({ boo => 100, thing => 123, other => 'def', array => 'a,b,c' });

is($bar->thing, 123);
is($bar->only, 100);
is($bar->other, 'def');
is($bar->thing(100), 100);
is($bar->thing, 100);
is($bar->other('abc'), 'abc');
is($bar->boo, 100);
is_deeply($bar->array, [qw/a b c/]);
is_deeply($bar->array('1,2,3'), [qw/1 2 3/]);
is_deeply($bar->array([4, 5, 6]), [qw/4 5 6/]);
is_deeply([$bar->modify], [qw/a b c d/]);

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
