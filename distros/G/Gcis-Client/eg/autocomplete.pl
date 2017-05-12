#!/usr/bin/env perl

use Gcis::Client;
use Data::Dumper;
use v5.14;

my $c = Gcis::Client->new(url => 'http://data.globalchange.gov');
my $got = $c->get('/autocomplete', {q => 'Wolfe', type => 'person'});
say Dumper($got);
$got = $c->get('/autocomplete?q=Wolfe&type=person');
say Dumper($got);

