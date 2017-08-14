use strict;
use Test::Lib;
use Test::More;
use Example::Delegates::Queue;

my $q = Example::Delegates::Queue::->new;

is $q->size => 0;

$q->push(1);
is $q->size => 1;

$q->push(2);
is $q->size => 2;

$q->pop;
is $q->size => 1;
done_testing();
