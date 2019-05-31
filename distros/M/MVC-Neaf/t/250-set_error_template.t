#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

neaf 404 => sub { +{-content => "Nothing at "   .shift->path }; },
    path => '/html';

neaf 403 => sub { +{-content => "Forbidden "    .shift->path }; },
    path => '/html';

neaf 403 => sub { +{-content => "No js for you ".shift->path }; },
    path => '/js';

get '/html/admin' => sub { die 403 };
get '/js/file.js' => sub { die 403 };

subtest "default 404" => sub {
    my @ret = neaf->run_test( '/' );
    is $ret[0], 404, "root not found";
    like $ret[2], qr(<span>404</span>), "common error message";
};

subtest "custom 404" => sub {
    my @ret = neaf->run_test( '/html/user' );
    is $ret[0], 404, "user not found";
    like $ret[2], qr(Nothing at /html/user), "html error message";
};

subtest "custom 403" => sub {
    my @ret = neaf->run_test( '/js/file.js' );
    is $ret[0], 403, "script not found";
    like $ret[2], qr(No js for you /js), "html error message";
};



done_testing;
