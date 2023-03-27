use warnings;
use strict;

BEGIN { unshift @INC, "./t/lib"; }
use Test::More tests => 96;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AVariable \"\$foo\" is not imported /;
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		"$]" < 5.008004;
	die "WARNING: $_[0]";
};

our @values;

@values = ();
eval q{
	use strict;
	push @values, $foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	use Lexical::Var '$foo' => \(my$x=2);
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		push @values, $foo;
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{ ; }
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	{
		use Lexical::Var '$foo' => \(my$x=1);
	}
	push @values, $foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	{
		use Lexical::Var '$foo' => \(my$x=1);
	}
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		use Lexical::Var '$foo' => \(my$x=2);
		push @values, $foo;
	}
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		use Lexical::Var '$foo' => \(my$x=2);
	}
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		use Lexical::Var '$foo' => \(my$x=2);
		push @values, $foo;
	}
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	package wibble;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	package wibble;
	use Lexical::Var '$foo' => \(my$x=1);
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	package wibble;
	use Lexical::Var '$foo' => \(my$x=1);
	package main;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	package wibble;
	use Lexical::Var '$foo' => \(my$x=2);
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	package wibble;
	use Lexical::Var '$foo' => \(my$x=2);
	package main;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		no Lexical::Var '$foo';
		push @values, $foo;
	}
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	no Lexical::Var '$bar';
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	no strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		no Lexical::Var '$foo';
		push @values, $foo;
	}
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		no Lexical::Var '$foo';
	}
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		no Lexical::Var '$foo' => \$foo;
		push @values, $foo;
	}
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		no Lexical::Var '$foo' => \$foo;
		push @values, $foo;
	}
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		no Lexical::Var '$foo' => \$foo;
	}
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		no Lexical::Var '$foo' => \(my$x=1);
		push @values, $foo;
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	{
		no Lexical::Var '$foo' => \(my$x=1);
	}
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	no strict;
	our $value_a = "aaa";
	use Lexical::Var '$foo' => \$value_a;
	sub {
		no Lexical::Var '$foo' => \$value_a;
		push @values, $foo;
	}->();
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	BEGIN { my $x = "foo\x{666}"; $x =~ /foo\p{Alnum}/; }
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	use t::scalar_0;
	push @values, $foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	use Lexical::Var '$foo' => \(my$x=1);
	use t::scalar_0n;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ undef, 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	use t::scalar_1;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	use t::scalar_2;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	use t::scalar_3;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	use t::scalar_4;
	push @values, $foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	use Lexical::Var '$foo' => \(my$x=1);
	use t::scalar_4n;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ undef, 1 ];

SKIP: { skip "no lexical propagation into string eval", 12 if "$]" < 5.009003;

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	eval q{
		use strict;
		push @values, $foo;
	};
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	eval q{
		use strict;
		use Lexical::Var '$foo' => \(my$x=1);
	};
	push @values, $foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	eval q{
		no strict;
		use Lexical::Var '$foo' => \(my$x=1);
	};
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	eval q{
		use strict;
		use Lexical::Var '$foo' => \(my$x=2);
		push @values, $foo;
	};
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	eval q{
		use strict;
		use Lexical::Var '$foo' => \(my$x=2);
	};
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	eval q{
		use strict;
		use Lexical::Var '$foo' => \(my$x=2);
		push @values, $foo;
	};
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

}

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	push @values, $foo;
	{
		my $foo = 2;
		push @values, $foo;
		use Lexical::Var '$foo' => \(my$x=3);
		push @values, $foo;
	}
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1, 2, 3, 1 ];

@values = ();
eval q{
	use strict;
	no warnings "$]" >= 5.027007 ? "shadow" : "misc";
	my $foo = 1;
	push @values, $foo;
	{
		use Lexical::Var '$foo' => \(my$x=2);
		push @values, $foo;
		my $foo = 3;
		push @values, $foo;
	}
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1, 2, 3, 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '$foo' => \(my$x=1);
	push @values, $foo;
	{
		our $foo;
		push @values, $foo;
		use Lexical::Var '$foo' => \(my$x=3);
		push @values, $foo;
	}
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 1, undef, 3, 1 ];

@values = ();
eval q{
	use strict;
	no warnings "$]" >= 5.027007 ? "shadow" : "misc";
	our $foo;
	push @values, $foo;
	{
		use Lexical::Var '$foo' => \(my$x=2);
		push @values, $foo;
		our $foo;
		push @values, $foo;
	}
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ undef, 2, undef, undef ];

@values = ();
eval q{
	use strict;
	no warnings "$]" >= 5.027007 ? "shadow" : "misc";
	use Lexical::Var '$foo' => \(my$x=2);
	push @values, $foo;
	our $foo;
	push @values, $foo;
	no Lexical::Var '$foo' => \$foo;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 2, undef, undef ];

@values = ();
eval q{
	use strict;
	no warnings "$]" >= 5.027007 ? "shadow" : "misc";
	use Lexical::Var '$foo' => \(my$x=2);
	use Lexical::Var '$foo_alias' => \$foo;
	push @values, $foo;
	our $foo;
	push @values, $foo;
	no Lexical::Var '$foo' => \$foo_alias;
	push @values, $foo;
};
is $@, "";
is_deeply \@values, [ 2, undef, undef ];

SKIP: { skip "\"class\" unavailable", 4 if "$]" < 5.037009;

@values = ();
eval q{
	use feature "class";
	no warnings "experimental::class";
	class Test0 {
		field $foo;
		use Lexical::Var '$foo' => \(my$x=2);
		push @values, $foo;
	}
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use feature "class";
	no warnings "experimental::class";
	class Test1 {
		field $foo = 1;
		method aa {
			push @values, $foo;
			use Lexical::Var '$foo' => \(my$x=2);
			push @values, $foo;
			use Lexical::Var '$self' => \(my$x=3);
			push @values, $self;
		}
	}
	Test1->new->aa;
};
is $@, "";
is_deeply \@values, [ 1, 2, 3 ];

}

1;
