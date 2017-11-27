#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::Request;

my $req = MVC::Neaf::Request->new;

like $req->id, qr/[0-9a-f]+/, "Some hexadecimals";
is $req->id, $req->id, "Subsequent calls identic";

$req->set_id( "foo" );
is $req->id, "foo", "set_id";

done_testing;
