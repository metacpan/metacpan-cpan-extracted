#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTTP::Headers::Fast;

use MVC::Neaf::Request;

my $req = MVC::Neaf::Request->new(
    header_in => HTTP::Headers::Fast->new(
        x_foo_bar => "foobared",
        x_multi   => [ "food", "bard" ],
    ),
);

is +$req->header_in("X-Foo-Bar"), "foobared", "no regex";
is +$req->header_in("X-Multi"), "food, bard", "no regex, scalar multivalue";
is_deeply [ $req->header_in("X-Multi") ], ["food", "bard"], "no regex, list multivalue";

lives_and {
    is +$req->header_in("X-Foo-Bar", qr/foo/), "foobared", "regex check";
};
throws_ok {
    $req->header_in("X-Foo-Bar", qr/xxx/);
} qr/^422/, "regex check fails";

lives_and {
    is_deeply [ $req->header_in("X-Multi", '[a-z]+') ], ["food", "bard"], "regex check, list multivalue";
};
throws_ok {
    $req->header_in("X-Multi", 'f.*');
} qr/^422/, "regex check fails (multivalue)";

done_testing;

