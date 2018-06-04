#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf::Util qw(decode_json);
use MVC::Neaf;

warnings_like {
    neaf default => '/foo' => { bar => 42 };
} [ qr#default.*DEPRECATED.*path# ], "Deprecation is there";

get '/foo/bar' => sub { +{} };

my ($status, undef, $content) = neaf->run_test( '/foo/bar' );
is $status, 200, "Successfully served";
$content = decode_json( $content );

is $content->{bar}, 42, "Default value propagated";

done_testing;
