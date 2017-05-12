use warnings;
use strict;

use Test::More tests => 4;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('@foo' => []) }
is_deeply \@foo, [];
push @foo, qw(x y);
is_deeply \@foo, [qw(x y)];
push @foo, qw(a b);
is_deeply \@foo, [qw(x y a b)];
$foo[2] = "A";
is_deeply \@foo, [qw(x y A b)];

1;
