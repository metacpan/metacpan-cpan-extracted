use warnings;
use strict;

use Test::More tests => 8;

our @x = (100, 200);
@x = @x;
sub foo ($) { $_[0]+1 }
our @values;

@values = ();
eval q{
	push @values, foo @x, 20;
	push @values, foo(@x);
};
is $@, "";
is_deeply \@values, [ 3, 20, 3 ];

@values = ();
eval q{
	no Lexical::Var '&foo';
	push @values, foo @x, 20;
	push @values, foo(@x);
};
is $@, "";
is_deeply \@values, [ 3, 20, 3 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { 1 };
	no Lexical::Var '&foo';
	push @values, foo @x, 20;
	push @values, foo(@x);
};
is $@, "";
is_deeply \@values, [ 3, 20, 3 ];

SKIP: { skip "\"my sub\" unavailable", 2 if "$]" < 5.017004;

@values = ();
eval q{
	no warnings "$]" >= 5.017005 ? "experimental::lexical_subs" :
		"experimental";
	use feature "lexical_subs";
	my sub foo { 1 }
	no Lexical::Var '&foo';
	push @values, foo @x, 20;
	push @values, foo(@x);
};
if("$]" < 5.019001) {
	like $@, qr/\Acan't shadow core lexical subroutine/;
	ok 1;
} else {
	is $@, "";
	is_deeply \@values, [ 3, 20, 3 ];
}

}

1;
