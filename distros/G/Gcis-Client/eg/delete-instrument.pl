#!/usr/bin/env perl

# Example :
#    ./delete-instrument.pl http://localhost:3000

use Gcis::Client;

my $url = $ARGV[0];

my $c = Gcis::Client->connect(url => $url);

$c->delete("/instrument/altimeter") or die $c->error;

