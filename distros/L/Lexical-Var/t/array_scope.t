use warnings;
use strict;

use Test::More tests => 22;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AVariable \"\@foo\" is not imported /;
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		"$]" < 5.008004;
	die "WARNING: $_[0]";
};

@main::foo = (undef);
@main::foo = (undef);

our @values;

@values = ();
eval q{
	use strict;
	push @values, @foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	push @values, @foo;
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [1];
	push @values, @foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [1];
	use Lexical::Var '@foo' => [2];
	push @values, @foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [1];
	{
		push @values, @foo;
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [1];
	{ ; }
	push @values, @foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	{
		use Lexical::Var '@foo' => [1];
	}
	push @values, @foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	{
		use Lexical::Var '@foo' => [1];
	}
	push @values, @foo;
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [1];
	{
		use Lexical::Var '@foo' => [2];
		push @values, @foo;
	}
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [1];
	{
		use Lexical::Var '@foo' => [2];
	}
	push @values, @foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [1];
	{
		use Lexical::Var '@foo' => [2];
		push @values, @foo;
	}
	push @values, @foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

1;
