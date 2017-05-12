#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Glib::JSON;

{
    my $gen = Glib::JSON::Generator->new();
    $gen->set_root(Glib::JSON::Node->new('null'));
    is_deeply([$gen->to_data()], [ 'null', length('null') ], 'null node');
}

{
    my $builder = Glib::JSON::Builder->new();

    $builder->begin_object();

        $builder->set_member_name('foo');
        $builder->add_int_value(42);

        $builder->set_member_name('bar');
        $builder->add_boolean_value(1);

    $builder->end_object();

    my $gen = Glib::JSON::Generator->new();
    $gen->set_root($builder->get_root());

    my ($data, $len) = $gen->to_data();
    is(length($data), $len);
    is($data, '{"foo":42,"bar":true}');
}
