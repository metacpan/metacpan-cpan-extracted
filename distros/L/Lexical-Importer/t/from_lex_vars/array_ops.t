use warnings;
use strict;

use Test::More tests => 10;

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
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('@foo' => [qw(a b c)]) }
	push @values, $#foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('@foo' => [qw(a b c)]) }
	push @values, $foo[1];
};
is $@, "";
is_deeply \@values, [ "b" ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('@foo' => [qw(a b c)]) }
	my $i = 1;
	push @values, $foo[$i];
};
is $@, "";
is_deeply \@values, [ "b" ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('@foo' => [qw(a b c)]) }
	push @values, @foo[1,2,0];
};
is $@, "";
is_deeply \@values, [ qw(b c a) ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('@foo' => [qw(a b c)]) }
	my @i = (1, 2, 0);
	push @values, @foo[@i];
};
is $@, "";
is_deeply \@values, [ qw(b c a) ];

1;
