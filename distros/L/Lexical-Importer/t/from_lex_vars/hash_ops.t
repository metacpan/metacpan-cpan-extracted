use warnings;
use strict;

use Test::More tests => 8;

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
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => { qw(a A b B c C) }) }
	push @values, $foo{b};
};
is $@, "";
is_deeply \@values, [ "B" ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => { qw(a A b B c C) }) }
	my $i = "b";
	push @values, $foo{$i};
};
is $@, "";
is_deeply \@values, [ "B" ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => { qw(a A b B c C) }) }
	push @values, @foo{qw(b c a)};
};
is $@, "";
is_deeply \@values, [ qw(B C A) ];

@values = ();
eval q{
	use strict;
	BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => { qw(a A b B c C) }) }
	my @i = qw(b c a);
	push @values, @foo{@i};
};
is $@, "";
is_deeply \@values, [ qw(B C A) ];

1;
