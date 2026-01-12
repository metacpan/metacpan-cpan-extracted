use v5.20;
use experimental 'signatures';
use Test2::V0;

# It's not German for "The Bart, The".
sub compiles ( $str ) { eval "$str; 1" }

ok compiles qq{
	package Local::Foo;
	use Marlin::Antlers;
};

my $x = Local::Foo->new;
isa_ok( $x, 'Local::Foo' );

# Same code as before, but now will refuse to compile.
ok !compiles qq{
	package Local::Foo;
	use Marlin::Antlers;
};

ok !compiles qq{
	package Local::Bar;
	use Marlin::Antlers;
	use Marlin::Role::Antlers;
};

ok !compiles qq{
	package Local::Baz;
	use Marlin;
	use Marlin::Antlers;
};

ok !compiles qq{
	package Local::Bam;
	use Moo;
	use Marlin::Antlers;
};

ok !compiles qq{
	package Local::Bat;
	use Moose;
	BEGIN { __PACKAGE__->meta->make_immutable };
	use Marlin::Antlers;
};

ok !compiles qq{
	package Local::Ban;
	use Mouse;
	use Marlin::Antlers;
};

done_testing;