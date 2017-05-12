#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Glib::JSON;

{
    my $array = Glib::JSON::Array->new();
    isa_ok($array, 'Glib::JSON::Array');
    is($array->get_length(), 0, 'empty array length = 0');
}

{
    my $array = Glib::JSON::Array->sized_new(4);
    isa_ok($array, 'Glib::JSON::Array');
    is($array->get_length(), 0, 'empty sized array length = 0');
}
