#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

my @call;

neaf->route( rest => sub { push @call, "me_get"; +{} }, method => 'GET' );
neaf->route( rest => sub { push @call, "me_post"; +{} }, method => 'POST' );

eval {
    neaf->route( rest => sub {}, method => 'GET' );
};
like ($@, qr/MVC::Neaf.*duplicate/, "Dupe handler = no go");
note $@;

my $app = neaf->run;

is ($app->( { REQUEST_METHOD => 'GET', REQUEST_URI => '/rest' } )->[0], 200
    , "Get ok" );
is ($app->( { REQUEST_METHOD => 'POST', REQUEST_URI => '/rest' } )->[0], 200
    , "Post ok" );
is ($app->( { REQUEST_METHOD => 'HEAD', REQUEST_URI => '/rest' } )->[0], 200
    , "Head ok - induced by GET" );

my @put405 = neaf->run_test(
    { REQUEST_METHOD => 'PUT', REQUEST_URI => '/rest' } );

is( $put405[0], 405, "Put gets 405 error");
like( $put405[1]->header("Allow"), qr/HEAD/, "Allow header present" );
is (join( ",", sort split /,\s*/, $put405[1]->header("Allow"))
    , 'GET,HEAD,POST', "Allow header as expected (after sort)");

is_deeply( \@call, [ "me_get", "me_post", "me_get" ], "Call sequence as expected" );

done_testing;
