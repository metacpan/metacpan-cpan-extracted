#!/usr/bin/env perl

# Example :
#    ./list-instruments.pl http://localhost:3000

use Gcis::Client;
use Data::Dumper;
use v5.14;

my $url = $ARGV[0];

my $c = Gcis::Client->new(url => $url);

for my $instrument ($c->get("/instrument", { all => 1 })) {
    say Dumper($instrument);
}

