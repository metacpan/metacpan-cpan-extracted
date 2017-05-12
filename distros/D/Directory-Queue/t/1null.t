#!perl

use strict;
use warnings;
use Directory::Queue::Null;
use Test::More tests => 4;

our($dq);

$dq = Directory::Queue::Null->new();
is($dq->count(), 0, "count 1");

$dq->add("whatever");
$dq->add({ foo => 1 });
is($dq->count(), 0, "count 2");

is($dq->first(), "", "first");
is($dq->next(), "", "next");
