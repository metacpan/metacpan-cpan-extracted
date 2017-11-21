#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf qw(:sugar);

get '/foo' => sub {
    my $req = shift;
    return { life => $req->param( "fine" ) || $req->param( "lie" ) };
}, param_regex => { fine => '\d+' };

get '/multi' => sub {
    my $req = shift;
    return { life => [ $req->multi_param( "fine" ) ] };
}, param_regex => { fine => '\d+' };

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

like neaf->run_test( '/foo?fine=42' ), qr/\{"life":"?42"?\}/, "Render ok";
is scalar @warn, 0, "No warnings";

is [neaf->run_test( '/foo?lie=42' )]->[0], 500, "Unexpected param = no go";
is scalar @warn, 1, "1 warning issued";
like $warn[0], qr/ERROR.*required/i, "Warn as expected";

note "WARN: $_" for @warn;

note "multi_param() test now";
@warn = ();

like neaf->run_test( '/multi' ), qr/\{"life":\[\]\}/, "Empty ok";
like neaf->run_test( '/multi?fine=42' ), qr/\{"life":\["?42"?\]\}/, "One ok";
like neaf->run_test( '/multi?fine=42&fine=137' ), qr/\{"life":\[[\d",]+\]\}/, "Multi ok";
like neaf->run_test( '/multi?fine=42&fine=nope' ), qr/\{"life":\[\]\}/, "Wrong ok, but empty";



done_testing;
