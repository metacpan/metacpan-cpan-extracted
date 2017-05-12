use warnings;
use strict;

use Test::More tests => 22;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AVariable \"\%foo\" is not imported /;
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		"$]" < 5.008004;
	die "WARNING: $_[0]";
};

%main::foo = (a=>undef);
%main::foo = (a=>undef);

our @values;

@values = ();
eval q{
	use strict;
	push @values, %foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>undef ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>1}) }
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>1 ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>1}) }
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>2}) }
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>2 ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>1}) }
	{
		push @values, %foo;
	}
};
is $@, "";
is_deeply \@values, [ a=>1 ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>1}) }
	{ ; }
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>1 ];

@values = ();
eval q{
	use strict;
	{
		BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>1}) }
	}
	push @values, %foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	{
		BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>1}) }
	}
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>undef ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>1}) }
	{
		BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>2}) }
		push @values, %foo;
	}
};
is $@, "";
is_deeply \@values, [ a=>2 ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>1}) }
	{
		BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>2}) }
	}
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>1 ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>1}) }
	{
		BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {a=>2}) }
		push @values, %foo;
	}
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>2, a=>1 ];

1;
