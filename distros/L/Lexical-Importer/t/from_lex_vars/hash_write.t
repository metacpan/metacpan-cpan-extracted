use warnings;
use strict;

use Test::More tests => 4;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { require Lexical::Importer; Lexical::Importer->_import_lex_var('%foo' => {}) }
is_deeply \%foo, {};
$foo{x} = "a";
is_deeply \%foo, {x=>"a"};
$foo{y} = "b";
is_deeply \%foo, {x=>"a",y=>"b"};
$foo{x} = "A";
is_deeply \%foo, {x=>"A",y=>"b"};

1;
