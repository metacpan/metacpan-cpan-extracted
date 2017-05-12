#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;

use Hash::PriorityQueue;

my $q = Hash::PriorityQueue->new();

# try to insert an already existing element.
# this one only tests the "checked" functions, because the unchecked functions
# might do anything and you've been warned...
$q->insert("a", 2);
$q->insert("a", 5);
$q->insert("b", 3);
is($q->pop(), "b", "1st retrieved element is b");
is($q->pop(), "a", "2nd retrieved element is a");
ok(!defined($q->pop()), "no 3rd element");

# if a non existing element is updated, it should be added.
# (note: future versions might recommend update() for everything, in this case
#  this test is irrelevant as insert() has already been tested.)
$q->insert("blah", 5);
$q->update("foo", 2);
is($q->pop(), "foo",  "1st retrieved element is foo");
is($q->pop(), "blah", "2nd retrieved element is blah");
ok(!defined($q->pop()), "no 3rd element");

