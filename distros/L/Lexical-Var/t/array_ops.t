use warnings;
use strict;

use Test::More tests => 14;

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
	use Lexical::Var '@foo' => [qw(a b c)];
	push @values, $#foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [qw(a b c)];
	push @values, $foo[1];
};
is $@, "";
is_deeply \@values, [ "b" ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [qw(a b c)];
	my $i = 1;
	push @values, $foo[$i];
};
is $@, "";
is_deeply \@values, [ "b" ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [qw(a b c)];
	push @values, @foo[1,2,0];
};
is $@, "";
is_deeply \@values, [ qw(b c a) ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '@foo' => [qw(a b c)];
	my @i = (1, 2, 0);
	push @values, @foo[@i];
};
is $@, "";
is_deeply \@values, [ qw(b c a) ];

SKIP: {
	skip "key/value array slicing not available on this Perl", 4
		unless "$]" >= 5.019004;

	@values = ();
	eval q{
		use strict;
		use Lexical::Var '@foo' => [qw(a b c)];
		push @values, %foo[1,2,0];
	};
	is $@, "";
	is_deeply \@values, [ 1, "b", 2, "c", 0, "a" ];

	@values = ();
	eval q{
		use strict;
		use Lexical::Var '@foo' => [qw(a b c)];
		my @i = (1, 2, 0);
		push @values, %foo[@i];
	};
	is $@, "";
	is_deeply \@values, [ 1, "b", 2, "c", 0, "a" ];
}

1;
