use strict;
use Test::Lib;
use Test::Most tests => 3;
use Example::Construction::Counter;

my $counter = Example::Construction::Counter->new({start => 10});

is $counter->next => 10;
is $counter->next => 11;
is $counter->next => 12;
