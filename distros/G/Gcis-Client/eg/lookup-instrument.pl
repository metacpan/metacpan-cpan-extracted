#!/usr/bin/env perl

use Gcis::Client;
use Data::Dumper;
use v5.14;

my $c = Gcis::Client->new(url => $ARGV[0]);

my $instrument = $c->get("/lexicon/ceos/find/instrumentID/374");

unless ($instrument) {
    say "not found";
    exit;
}

say "uri : $instrument->{uri}";
say "data : ".Dumper($instrument);

