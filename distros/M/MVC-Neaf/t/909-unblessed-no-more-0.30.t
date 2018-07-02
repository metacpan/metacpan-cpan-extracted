#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

# NOTE! This is NOT about set_path_defaults being deprecated
# This is about MVC::Neaf->method call being deprecated
warnings_like {
    MVC::Neaf->add_route( '/neaf' => sub {} );
} [ qr/MVC::Neaf->add_route.*DEPRECATED.*neaf.*new/ ], "Deprecated warning";

eval {
    MVC::Neaf::Route::Main->add_route( '/main' => sub { } );
};
like $@, qr#[Uu]nblessed#, "Everything EXCEPT default neaf just dies";

done_testing;
