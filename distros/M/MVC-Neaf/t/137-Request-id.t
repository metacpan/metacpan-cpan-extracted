#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::Request;

my $req = MVC::Neaf::Request->new;

like $req->id, qr/^[-_~+\/0-9a-zA-Z]+$/, "Some characters in id";
is $req->id, $req->id, "Subsequent calls identic: ".$req->id;

$req->set_id( "foo" );
is $req->id, "foo", "set_id";

done_testing;
