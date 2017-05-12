#!/usr/bin/env perl

use 5.10.0;
use strict;
use warnings;

use Limper;

my $generic = sub {
    headers('Content-Type' => 'application/json');
    "{\"status\":\"OK\"}\n";
};

get qr{^/} => $generic;
post qr{^/} => $generic;

limp({listeners => 5});
