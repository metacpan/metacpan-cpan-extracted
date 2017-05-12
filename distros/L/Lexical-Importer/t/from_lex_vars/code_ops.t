use warnings;
use strict;

use Test::More tests => 12;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		"$]" < 5.008004;
	die "WARNING: $_[0]";
};

sub main::foo { "main" }
sub main::bar () { "main" }

our @values;

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('&foo' => sub () { 1 }) }
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('&foo' => sub () { 1 }) }
	push @values, &foo();
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('&foo' => sub ($) { 1+$_[0] }) }
	push @values, &foo(10);
	push @values, &foo(20);
};
is $@, "";
is_deeply \@values, [ 11, 21 ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('&foo' => sub ($) { 1+$_[0] }) }
	my @a = (10, 20);
	push @values, &foo(@a);
};
is $@, "";
is_deeply \@values, [ 11 ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('&bar' => sub () { 1 }) }
	push @values, &bar;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('&bar' => sub () { 1 }) }
	push @values, &bar();
};
is $@, "";
is_deeply \@values, [ 1 ];

1;
