#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON;

use MVC::Neaf;
use MVC::Neaf::X::Form::LIVR;

if ( !eval {require Validator::LIVR;} ) {
    plan skip_all => "No LIVR found, skipping";
};

my $val = MVC::Neaf::X::Form::LIVR->new({
    foo => 'required',
    bar => 'integer',
    baz => { like => '^%\w+$' },
});

MVC::Neaf->route( "/" => sub {
    my $req = shift;

#    note " ########## ", explain $req;

    my $form = $req->form( $val );

    return {
        form => $form->data,
        fail => $form->error,
        raw  => $form->raw,
    };
}, view => 'JS' );

my $app = MVC::Neaf->run;

my $reply;

$reply = $app->({
    REQUEST_METHOD => 'GET',
    QUERY_STRING => "bar=42",
})->[2][0];
is_deeply (decode_json($reply)
    , {form => {}, fail => {foo=>"REQUIRED"}, raw =>{ bar => 42 } }
    , "Form processed - 1")
    or diag $reply;

$reply = $app->({
    REQUEST_METHOD => 'GET',
    QUERY_STRING => "foo=1&bar=xxx",
})->[2][0];
is_deeply (decode_json($reply)
    , {form => {}, fail => { bar=>"NOT_INTEGER"}, raw => { foo => 1, bar => "xxx" } }
    , "Form processed - 2")
    or diag $reply;

$reply = $app->({
    REQUEST_METHOD => 'GET',
    QUERY_STRING => "foo=1",
})->[2][0];
is_deeply (decode_json($reply)
    , {form => {foo => 1}, fail => {}, raw => { foo=> 1} }
    , "Form processed - 3")
    or diag $reply;

done_testing;
