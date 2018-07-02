#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use MVC::Neaf::Util qw(decode_json decode_b64);

use MVC::Neaf;

neaf session => 'MVC::Neaf::X::Session::Cookie'
    , key => 'not_so_secret'
    , view_as => 'my_data'
    , cookie => 'gotcha';
get '/login' => sub {
    my $req = shift;
    $req->save_session( { foo => 42 } );
    +{};
};

get '/admin' => sub {
    my $req = shift;

    +{here => 'dragons'};
};

my ($status, $head, $content) = neaf->run_test( '/login' );

is_deeply decode_json($content), { my_data => { foo => 42 } }
    , "session made it to template";
my $cook = $head->header( 'Set-Cookie' );
ok $cook, "Some cookie present";
ok $cook =~ qr#(gotcha=[^ ]+)#, "Session cookie extracted";

my $sess = $1;
note $sess;

($status, $head, $content) = neaf->run_test( '/admin', cookie => $sess );
is_deeply decode_json($content)
    , { my_data => { foo=>42 }, here => 'dragons' }
    , "Session round-trip";

done_testing;
