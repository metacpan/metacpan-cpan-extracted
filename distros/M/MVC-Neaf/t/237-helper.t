#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use MVC::Neaf::Util qw(decode_json);

use MVC::Neaf;

my $handler = sub {
    my $req = shift;

    +{ global => $req->my_global, local => $req->my_local, path => $req->path };
};

neaf->set_helper( my_global => sub { "global:".ref $_[0] } );
neaf->set_helper( my_local  => sub { "not to be seen" }, exclude => '/none' );
neaf->set_helper( my_local  => sub { "onlyfoo" }, path => '/foo' );
neaf->set_helper( my_local  => sub { "onlybar" }, path => '/foo/bar' );

get '/foo' => $handler;
get '/foo/bar/baz' => $handler;
get '/none' => $handler;

my ($status, $head, $content);

{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };
    ($status, $head, $content) = neaf->run_test( '/foo' );
    is scalar @warn, 0, "No warnings";
    note "WARN: $_" for @warn;
};
is $status, 200, "Request works";
is_deeply decode_json($content), {
    global => 'global:MVC::Neaf::Request::PSGI',
    local  => 'onlyfoo',
    path   => '/foo',
}, "Content as expected";

{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };
    ($status, $head, $content) = neaf->run_test( '/foo/bar/baz' );
    is scalar @warn, 0, "No warnings";
    note "WARN: $_" for @warn;
};

is $status, 200, "Request works";
is_deeply decode_json($content), {
    global => 'global:MVC::Neaf::Request::PSGI',
    local  => 'onlybar',
    path   => '/foo/bar/baz',
}, "Content as expected";

{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };
    ($status, $head, $content) = neaf->run_test( '/none' );
    is scalar @warn, 1, "1 warning issued - TODO may break after on_error fix";
    like $warn[0], qr#[Hh]elper.*my_local.*GET /none#, "Warning about bad helper";
    note "WARN: $_" for @warn;
};
is $status, 500, "Request doesn't work";
note $content;

done_testing;
