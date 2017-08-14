use strict;
use Test::Lib;
use Test::Most tests => 5;
use Example::Construction::Counter;

my $counter = Example::Construction::Counter::->new({start => 10});

is $counter->next => 10;
is $counter->next => 11;
is $counter->next => 12;

TODO: {
    local $TODO = "Superseded by contracts";
    throws_ok { Example::Construction::Counter::->new } qr/Mandatory parameter 'start' missing/;
    throws_ok { Example::Construction::Counter::->new(start => 'abc') } 
            qr/The 'start' parameter \Q("abc")\E to Example::Construction::Counter::new did not pass the 'is_integer' callback/;
}
