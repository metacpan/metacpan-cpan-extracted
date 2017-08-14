use strict;
use Test::Lib;
use Test::Most tests => 3;
use Example::Construction::Counter_v3;

my $counter = Example::Construction::Counter_v3::->new(10);

is $counter->next => 10;
is $counter->next => 11;
is $counter->next => 12;
