use warnings;
use strict;

use Test::More tests => 18;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		"$]" < 5.008004;
	die "WARNING: $_[0]";
};

$main::one = 1;
$main::one = 1;
$main::two = 2;
$main::two = 2;

our @values;

@values = ();
eval q{
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*one) }
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*one) }
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*two) }
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*one) }
	{
		push @values, ${*foo{SCALAR}};
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*one) }
	{ ; }
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	{
		BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*one) }
	}
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*one) }
	{
		BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*two) }
		push @values, ${*foo{SCALAR}};
	}
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*one) }
	{
		BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*two) }
	}
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*one) }
	{
		BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('*foo' => \*two) }
		push @values, ${*foo{SCALAR}};
	}
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

1;
