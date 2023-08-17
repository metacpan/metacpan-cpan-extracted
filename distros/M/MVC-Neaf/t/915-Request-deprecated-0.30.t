#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use MVC::Neaf::Request;

my $req = MVC::Neaf::Request->new;

throws_ok {
    $req->set_default
} qr/DEPRECATED/, 'no set_default';

throws_ok {
    $req->get_default
} qr/DEPRECATED/, 'no get_default';

done_testing;
