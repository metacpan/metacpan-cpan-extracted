#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

warnings_like {
    neaf->load_resources( \<<"RES" );
@@ foo.bar garbage=42
RES
} [ { carped => qr#[Uu]nknown.*garbage# } ], "Unknown fields = no go";

warnings_like {
    neaf->load_resources( \<<"RES" );
@@ foo.bar view=JS
RES
} [ { carped => qr#[Uu]nknown.*view.*JS# } ], "JS not loaded";

neaf view => JS => 'JS';

warnings_like {
    neaf->load_resources( \<<"RES" );
@@ foo.bar view=JS
RES
} [ { carped => qr#[Vv]iew.*JS.*preload# } ], "JS cannot preload()";

eval {
    neaf->load_resources( \<<"RES" );
@@ /foo.jpg
@@ /foo.jpg
RES
};
like $@, qr#[Dd]uplicate.*foo\.jpg#, "Duplicate = no go";

done_testing;
