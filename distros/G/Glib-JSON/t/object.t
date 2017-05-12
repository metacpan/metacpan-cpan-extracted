#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use Glib::JSON;

{
    my $object = Glib::JSON::Object->new();
    isa_ok($object, 'Glib::JSON::Object');
    is($object->get_size(), 0, 'empty object size = 0');
}
