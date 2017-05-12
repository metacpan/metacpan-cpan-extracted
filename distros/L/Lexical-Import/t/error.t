use warnings;
use strict;

use Test::More tests => 13;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

require_ok "Lexical::Import";

eval q{ Lexical::Import->import(); };
like $@, qr/\ALexical::Import does no default importation/;
eval q{ Lexical::Import->unimport(); };
like $@, qr/\ALexical::Import does not support unimportation/;

eval q{ Lexical::Import->import(["t::Exp1"], undef); };
like $@, qr/\Anon-array in Lexical::Import multi-import list/;

eval q{ Lexical::Import->import(undef); };
like $@, qr/\ALexical::Import needs the name of a module to import from/;
eval q{ Lexical::Import->import({}); };
like $@, qr/\ALexical::Import needs the name of a module to import from/;

eval q{ Lexical::Import->import(""); };
like $@, qr/\Amalformed module name `'/;
eval q{ Lexical::Import->import("Foo'Bar"); };
like $@, qr/\Amalformed module name `Foo'Bar'/;
eval q{ Lexical::Import->import("Foo+Bar"); };
like $@, qr/\Amalformed module name `Foo\+Bar'/;
eval q{ Lexical::Import->import("0Foo"); };
like $@, qr/\Amalformed module name `0Foo'/;

eval q{ Lexical::Import->import("Foo-Bar"); };
like $@, qr/\Amalformed module name `Foo-Bar'/;
eval q{ Lexical::Import->import("Foo-1."); };
like $@, qr/\Amalformed module name `Foo-1\.'/;
eval q{ Lexical::Import->import("Foo-v1"); };
like $@, qr/\Amalformed module name `Foo-v1'/;

1;
