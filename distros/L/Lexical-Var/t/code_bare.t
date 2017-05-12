use warnings;
use strict;

use Test::More;
BEGIN {
	plan skip_all => "bare subs impossible on this perl"
		if "$]" < 5.011002;
}
plan tests => 2*10*6;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		"$]" < 5.008004;
	die "WARNING: $_[0]";
};

our @x = (100, 200);

our @values;

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { rand() < 2 ? 123 : 0 };
	push @values, foo;
};
is $@, "";
is_deeply \@values, [ 123 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { rand() < 2 ? 123 : 0 };
	push @values, foo + 10;
};
is $@, "";
is_deeply \@values, [ 133 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { rand() < 2 ? 123 : 0 };
	push @values, foo 10;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { rand() < 2 ? 123 : 0 };
	push @values, foo 10, 20;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { rand() < 2 ? 123 : 0 };
	push @values, foo @x;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { rand() < 2 ? 123 : 0 };
	push @values, foo { 10+20; };
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { rand() < 2 ? 123 : 0 };
	push @values, foo();
};
is $@, "";
is_deeply \@values, [ 123 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { rand() < 2 ? 123 : 0 };
	push @values, foo(10);
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { rand() < 2 ? 123 : 0 };
	push @values, foo(10, 20);
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { rand() < 2 ? 123 : 0 };
	push @values, foo(@x);
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 123 };
	push @values, foo;
};
is $@, "";
is_deeply \@values, [ 123 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 123 };
	push @values, foo + 10;
};
is $@, "";
is_deeply \@values, [ 133 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 123 };
	push @values, foo 10;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 123 };
	push @values, foo 10, 20;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 123 };
	push @values, foo @x;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 123 };
	push @values, foo { 10+20; };
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 123 };
	push @values, foo();
};
is $@, "";
is_deeply \@values, [ 123 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 123 };
	push @values, foo(10);
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 123 };
	push @values, foo(10, 20);
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub () { 123 };
	push @values, foo(@x);
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { $_[0]+1 };
	push @values, foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { $_[0]+1 };
	push @values, foo + 10;
};
is $@, "";
is_deeply \@values, [ 11 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { $_[0]+1 };
	push @values, foo 10;
};
is $@, "";
is_deeply \@values, [ 11 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { $_[0]+1 };
	push @values, foo 10, 20;
};
is $@, "";
is_deeply \@values, [ 11, 20 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { $_[0]+1 };
	push @values, foo @x;
};
is $@, "";
is_deeply \@values, [ 3 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { $_[0]+1 };
	push @values, foo { 10+20; };
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { $_[0]+1 };
	push @values, foo();
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { $_[0]+1 };
	push @values, foo(10);
};
is $@, "";
is_deeply \@values, [ 11 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { $_[0]+1 };
	push @values, foo(10, 20);
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub ($) { $_[0]+1 };
	push @values, foo(@x);
};
is $@, "";
is_deeply \@values, [ 3 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (@) { "a", map { $_+1 } @_ };
	push @values, foo;
};
is $@, "";
is_deeply \@values, [ "a" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (@) { "a", map { $_+1 } @_ };
	push @values, foo + 10;
};
is $@, "";
is_deeply \@values, [ "a", 11 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (@) { "a", map { $_+1 } @_ };
	push @values, foo 10;
};
is $@, "";
is_deeply \@values, [ "a", 11 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (@) { "a", map { $_+1 } @_ };
	push @values, foo 10, 20;
};
is $@, "";
is_deeply \@values, [ "a", 11, 21 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (@) { "a", map { $_+1 } @_ };
	push @values, foo @x;
};
is $@, "";
is_deeply \@values, [ "a", 101, 201 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (@) { "a", map { $_+1 } @_ };
	push @values, foo { 10+20; };
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (@) { "a", map { $_+1 } @_ };
	push @values, foo();
};
is $@, "";
is_deeply \@values, [ "a" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (@) { "a", map { $_+1 } @_ };
	push @values, foo(10);
};
is $@, "";
is_deeply \@values, [ "a", 11 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (@) { "a", map { $_+1 } @_ };
	push @values, foo(10, 20);
};
is $@, "";
is_deeply \@values, [ "a", 11, 21 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (@) { "a", map { $_+1 } @_ };
	push @values, foo(@x);
};
is $@, "";
is_deeply \@values, [ "a", 101, 201 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { "b", map { $_+1 } @_ };
	push @values, foo;
};
is $@, "";
is_deeply \@values, [ "b" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { "b", map { $_+1 } @_ };
	push @values, foo + 10;
};
is $@, "";
is_deeply \@values, [ "b", 11 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { "b", map { $_+1 } @_ };
	push @values, foo 10;
};
is $@, "";
is_deeply \@values, [ "b", 11 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { "b", map { $_+1 } @_ };
	push @values, foo 10, 20;
};
is $@, "";
is_deeply \@values, [ "b", 11, 21 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { "b", map { $_+1 } @_ };
	push @values, foo @x;
};
is $@, "";
is_deeply \@values, [ "b", 101, 201 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { "b", map { $_+1 } @_ };
	push @values, foo { 10+20; };
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { "b", map { $_+1 } @_ };
	push @values, foo();
};
is $@, "";
is_deeply \@values, [ "b" ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { "b", map { $_+1 } @_ };
	push @values, foo(10);
};
is $@, "";
is_deeply \@values, [ "b", 11 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { "b", map { $_+1 } @_ };
	push @values, foo(10, 20);
};
is $@, "";
is_deeply \@values, [ "b", 11, 21 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub { "b", map { $_+1 } @_ };
	push @values, foo(@x);
};
is $@, "";
is_deeply \@values, [ "b", 101, 201 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (&) { "c", $_[0]->()+1 };
	push @values, foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (&) { "c", $_[0]->()+1 };
	push @values, foo + 10;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (&) { "c", $_[0]->()+1 };
	push @values, foo 10;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (&) { "c", $_[0]->()+1 };
	push @values, foo 10, 20;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (&) { "c", $_[0]->()+1 };
	push @values, foo @x;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (&) { "c", $_[0]->()+1 };
	push @values, foo { 10+20; };
};
is $@, "";
is_deeply \@values, [ "c", 31 ];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (&) { "c", $_[0]->()+1 };
	push @values, foo();
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (&) { "c", $_[0]->()+1 };
	push @values, foo(10);
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (&) { "c", $_[0]->()+1 };
	push @values, foo(10, 20);
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	use Lexical::Var '&foo' => sub (&) { "c", $_[0]->()+1 };
	push @values, foo(@x);
};
isnt $@, "";
is_deeply \@values, [];

1;
