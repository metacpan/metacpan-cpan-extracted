use warnings;
use strict;

BEGIN { unshift @INC, "./t/lib"; }
use Test::More tests => 86;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		"$]" < 5.008004;
	die "WARNING: $_[0]";
};

sub main::foo { "main" }
sub wibble::foo { "wibble" }

our @values;

@values = ();
eval q{
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use Lexical::Var '&foo' => sub { 2 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{ ; }
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	{
		use Lexical::Var '&foo' => sub { 1 };
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		use Lexical::Var '&foo' => sub { 2 };
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		use Lexical::Var '&foo' => sub { 2 };
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		use Lexical::Var '&foo' => sub { 2 };
		push @values, &foo;
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	package wibble;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	package wibble;
	use Lexical::Var '&foo' => sub { 1 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	package wibble;
	use Lexical::Var '&foo' => sub { 1 };
	package main;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	package wibble;
	use Lexical::Var '&foo' => sub { 2 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	package wibble;
	use Lexical::Var '&foo' => sub { 2 };
	package main;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo';
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '&foo' => sub { 1 };
	no Lexical::Var '&bar';
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo';
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo' => \&foo;
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo' => \&foo;
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo' => sub { 1 };
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	{
		no Lexical::Var '&foo' => sub { 1 };
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => \&wibble::foo;
	sub {
		no Lexical::Var '&foo' => \&wibble::foo;
		push @values, &foo;
	}->();
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	BEGIN { my $x = "foo\x{666}"; $x =~ /foo\p{Alnum}/; }
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use t::code_0;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main", 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use t::code_1;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use t::code_2;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use t::code_3;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	use t::code_4;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main", 1 ];

SKIP: { skip "no lexical propagation into string eval", 10 if "$]" < 5.009003;

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	eval q{
		push @values, &foo;
	};
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	eval q{
		use Lexical::Var '&foo' => sub { 1 };
	};
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	eval q{
		use Lexical::Var '&foo' => sub { 2 };
		push @values, &foo;
	};
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	eval q{
		use Lexical::Var '&foo' => sub { 2 };
	};
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	eval q{
		use Lexical::Var '&foo' => sub { 2 };
		push @values, &foo;
	};
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

}

SKIP: { skip "\"my sub\" unavailable", 18 if "$]" < 5.017004;

@values = ();
eval q{
	no warnings "$]" >= 5.017005 ? "experimental::lexical_subs" :
		"experimental";
	use feature "lexical_subs";
	use Lexical::Var '&foo' => sub { 1 };
	push @values, &foo;
	{
		push @values, &foo;
		my sub foo { 2 }
		push @values, &foo;
	}
	push @values, &foo;
	use Lexical::Var '&foo' => sub { 3 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1, 1, 2, 1, 3 ];

@values = ();
eval q{
	no warnings "$]" >= 5.017005 ? "experimental::lexical_subs" :
		"experimental";
	use feature "lexical_subs";
	BEGIN {
		my sub foo { 2 }
		"Lexical::Var"->import('&foo' => sub { 1 });
	}
	push @values, &foo;
	use Lexical::Var '&foo' => sub { 3 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1, 3 ];

@values = ();
eval q{
	no warnings "$]" >= 5.017005 ? "experimental::lexical_subs" :
		"experimental";
	use feature "lexical_subs";
	use Lexical::Var '&foo' => sub { 1 };
	push @values, &foo;
	{
		my sub foo { 2 }
		push @values, &foo;
		use Lexical::Var '&foo' => sub { 3 };
		push @values, &foo;
	}
	push @values, &foo;
};
if("$]" < 5.019001) {
	like $@, qr/\Acan't shadow core lexical subroutine/;
	ok 1;
} else {
	is $@, "";
	is_deeply \@values, [ 1, 2, 3, 1 ];
}

@values = ();
eval q{
	no warnings "$]" >= 5.017005 ? "experimental::lexical_subs" :
		"experimental";
	use feature "lexical_subs";
	no warnings "$]" >= 5.027007 ? "shadow" : "misc";
	my sub foo { 1 }
	push @values, &foo;
	{
		use Lexical::Var '&foo' => sub { 2 };
		push @values, &foo;
		my sub foo { 3 }
		push @values, &foo;
	}
	push @values, &foo;
};
if("$]" < 5.019001) {
	like $@, qr/\Acan't shadow core lexical subroutine/;
	ok 1;
} else {
	is $@, "";
	is_deeply \@values, [ 1, 2, 3, 1 ];
}

@values = ();
eval q{
	no warnings "$]" >= 5.017005 ? "experimental::lexical_subs" :
		"experimental";
	use feature "lexical_subs";
	use Lexical::Var '&foo' => sub { 1 };
	push @values, &foo;
	{
		our sub foo;
		push @values, &foo;
		use Lexical::Var '&foo' => sub { 3 };
		push @values, &foo;
	}
	push @values, &foo;
};
if("$]" < 5.019001) {
	like $@, qr/\Acan't shadow core lexical subroutine/;
	ok 1;
} else {
	is $@, "";
	is_deeply \@values, [ 1, "main", 3, 1 ];
}

@values = ();
eval q{
	no warnings "$]" >= 5.017005 ? "experimental::lexical_subs" :
		"experimental";
	use feature "lexical_subs";
	no warnings "$]" >= 5.027007 ? "shadow" : "misc";
	our sub foo;
	push @values, &foo;
	{
		use Lexical::Var '&foo' => sub { 2 };
		push @values, &foo;
		our sub foo;
		push @values, &foo;
	}
	push @values, &foo;
};
if("$]" < 5.019001) {
	like $@, qr/\Acan't shadow core lexical subroutine/;
	ok 1;
} else {
	is $@, "";
	is_deeply \@values, [ "main", 2, "main", "main" ];
}

@values = ();
eval q{
	no warnings "$]" >= 5.017005 ? "experimental::lexical_subs" :
		"experimental";
	use feature "lexical_subs";
	our sub foo;
	push @values, &foo;
	no Lexical::Var '&foo';
	push @values, &foo;
};
if("$]" < 5.019001) {
	like $@, qr/\Acan't shadow core lexical subroutine/;
	ok 1;
} else {
	is $@, "";
	is_deeply \@values, [ "main", "main" ];
}

@values = ();
eval q{
	no warnings "$]" >= 5.017005 ? "experimental::lexical_subs" :
		"experimental";
	use feature "lexical_subs";
	no warnings "$]" >= 5.027007 ? "shadow" : "misc";
	use Lexical::Var '&foo' => sub { 2 };
	push @values, &foo;
	package wibble;
	our sub foo;
	package main;
	push @values, &foo;
	no Lexical::Var '&foo' => \&foo;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, "wibble", "wibble" ];

@values = ();
eval q{
	no warnings "$]" >= 5.017005 ? "experimental::lexical_subs" :
		"experimental";
	use feature "lexical_subs";
	no warnings "$]" >= 5.027007 ? "shadow" : "misc";
	use Lexical::Var '&foo' => sub { 2 };
	use Lexical::Var '&foo_alias' => \&foo;
	push @values, &foo;
	package wibble;
	our sub foo;
	package main;
	push @values, &foo;
	no Lexical::Var '&foo' => \&foo_alias;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, "wibble", "wibble" ];

}

SKIP: { skip "builtin unavailable", 2 if "$]" < 5.035007;

@values = ();
eval q{
	no if "$]" >= 5.035009, warnings => "experimental::builtin";
	no warnings "$]" >= 5.027007 ? "shadow" : "misc";
	use Lexical::Var '&blessed' => sub { 2 };
	push @values, &blessed(bless([]));
	use builtin qw(blessed);
	push @values, &blessed(bless([]));
	use Lexical::Var '&blessed' => sub { 3 };
	push @values, &blessed(bless([]));
};
is $@, "";
is_deeply \@values, [ 2, "main", 3 ];

}

1;
