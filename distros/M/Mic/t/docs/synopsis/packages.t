use strict;
use Test::Lib;
use Test::Most tests => 5;
use Example::Synopsis::Counter;

my $counter = Example::Synopsis::Counter::->new;

is $counter->next => 0;
is $counter->next => 1;
is $counter->next => 2;

throws_ok { $counter->new } qr/Can't locate object method "new"/;
throws_ok { Example::Synopsis::Counter::->next } 
          qr/Can't locate object method "next" via package "Example::Synopsis::Counter"/;
