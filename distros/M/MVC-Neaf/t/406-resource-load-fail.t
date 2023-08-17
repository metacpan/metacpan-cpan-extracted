#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;

use MVC::Neaf;

warnings_like {
    neaf->load_resources( \<<"RES" );
@@ foo.bar garbage=42
RES
} [ { carped => qr([Uu]nknown.*garbage) } ], "Unknown fields = no go";

warnings_like {
    neaf->load_resources( \<<"RES" );
@@ foo.bar view=JS
RES
} [ { carped => qr([Uu]nknown.*view.*JS) } ], "JS not loaded";

neaf view => JS => 'JS';

warnings_like {
    neaf->load_resources( \<<"RES" );
@@ foo.bar view=JS
RES
} [ { carped => qr([Vv]iew.*JS.*preload) } ], "JS cannot preload()";

throws_ok {
    neaf->load_resources( \<<"RES" );
@@ /foo.jpg
@@ /foo.jpg
RES
} qr([Dd]uplicate.*foo\.jpg), "Duplicate = no go";

throws_ok {
    my $var;
    neaf->load_resources( \$var );
} qr(load_resources.*ailed), 'undef scalar = no go';

throws_ok {
    neaf->load_resources( [] );
} qr(load_resources.*must be.*scalar.*file), 'unexpected type = no go';

subtest 'filename' => sub {
    my $app = MVC::Neaf->new;

    my $fname = __FILE__.'.res';

    lives_ok {
        $app->load_resources( $fname );
        $app->load_resources( $fname );
    } 'load succeeded';
    my $list = $app->get_routes();
    ok $list->{'/file.txt'}{GET}, 'static file added to routes';
};

done_testing;

