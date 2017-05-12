#!/usr/bin/perl

use Memcached::Client::Serializer;
use Test::More tests => 5;

ok (my $serializer = Memcached::Client::Serializer->new, 'Create a new instance of the abstract base class');
is (eval {$serializer->deserialize}, undef, 'Watch ->deserialize fail');
ok ($@, 'Make sure it did fail');
is (eval {$serializer->serialize}, undef, 'Watch ->serialize fail');
ok ($@, 'Make sure it did fail');
