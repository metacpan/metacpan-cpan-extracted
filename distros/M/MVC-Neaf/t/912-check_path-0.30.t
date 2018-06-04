#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

warnings_like {
    get '/foo/:param' => sub { +{} };
} qr#[Cc]har.*outside.*DEPRECATED.*0\.30#, "Deprecated warning there";

my ($status) = neaf->run_test( '/foo/:param' );
is $status, 200, "Still able to work with a bad path";

done_testing;
