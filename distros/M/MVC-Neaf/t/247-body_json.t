#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf;

post '/api' => sub {
    my $req = shift;

    my $data = $req->body_json;
    return { -payload => $data };
};

subtest "happy case" => sub {
    my @resp = neaf->run_test(
        '/api',
        method => 'POST',
        body   => '{"foo":42}',
    );
    is $resp[0], 200, "http ok";
    is $resp[2], '{"foo":42}', 'data round-trip';
};

subtest "happy case with header" => sub {
    my @resp = neaf->run_test(
        '/api',
        method => 'POST',
        body   => '{"foo":42}',
        header => { 'Content-Type' => 'application/json' },
    );
    is $resp[0], 200, "http ok";
    is $resp[2], '{"foo":42}', 'data round-trip';
};

subtest "non-reference" => sub {
    my @resp = neaf->run_test(
        '/api',
        method => 'POST',
        body   => 'null',
        header => { 'Content-Type' => 'application/json' },
    );
    is $resp[0], 200, "http ok";
    is $resp[2], 'null', 'data round-trip';
};

subtest "broken json" => sub {
    warnings_like {
    my @resp = neaf->run_test(
        '/api',
        method => 'POST',
        body   => '{"foo":42',
        header => { 'Content-Type' => 'application/json' },
    );
    is $resp[0], 422, "http bad entity";
    } [qr/Failed to read JSON/], "warning emitted";
};

subtest "wrong header" => sub {
    warnings_like {
    my @resp = neaf->run_test(
        '/api',
        method => 'POST',
        body   => '{"foo":42}',
        header => { 'Content-Type' => 'text/xml' },
    );
    is $resp[0], 422, "http bad entity";
    } [qr/Failed to read JSON/], "warning emitted";
};

done_testing;
