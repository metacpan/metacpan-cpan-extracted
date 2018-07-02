#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

get '/foo' => sub {
    my $req = shift;

    { bar => $req->param("bar") };
}, param_regex => { bar => '\d+' }, strict => 1;

subtest "missing" => sub {
    my ($status, undef, $content) = neaf->run_test( '/foo' );
    is $status, 200, "Not died because of missing param";
    is $content, q{{"bar":null}}, "Json as expected";
};
subtest "present but empty" => sub {
    my ($status, undef, $content) = neaf->run_test( '/foo?bar=' );
    is $status, 200, "Not died because of missing param";
    is $content, q{{"bar":null}}, "Json as expected";
};

done_testing;
