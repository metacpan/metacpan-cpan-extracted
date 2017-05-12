#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use MARC::Batch;
my $b = MARC::Batch->new('JSON', './t/records.json');

my $n = 100;
while (my $r = $b->next()) {
    is $r->subfield('999', 'c'), $n++;
}

done_testing;
