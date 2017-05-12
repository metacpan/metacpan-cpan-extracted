#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Finance::Nadex;
use Finance::Nadex::Contract;
use Finance::Nadex::Order;
use Finance::Nadex::Position;


my $client = Finance::Nadex->new();

ok(ref $client eq 'Finance::Nadex', 'new() instantiates Finance::Nadex objects');

done_testing();


