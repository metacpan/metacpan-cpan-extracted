#!/usr/bin/env perl

use v5.14;

use Gcis::Client;
use Data::Dumper;
use Encode;

my $c = Gcis::Client->connect(url => $ARGV[0]);

my $ok = $c->get("/login");

say Dumper($ok);


