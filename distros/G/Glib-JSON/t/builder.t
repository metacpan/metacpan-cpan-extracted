#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;
use Glib::JSON;

{
    # build a JSON structure
    my $builder = Glib::JSON::Builder->new();
    isa_ok($builder, 'Glib::JSON::Builder');

    # {
    #   "url" : "http://www.gnome.org/img/flash/two-thirty.png"
    #   "size" : [ 652, 242 ]
    # }
    $builder->begin_object();

    $builder->set_member_name("url");
    $builder->add_string_value("http://www.gnome.org/img/flash/two-thirty.png");

    $builder->set_member_name("size");
    $builder->begin_array();
    $builder->add_int_value(652);
    $builder->add_int_value(242);
    $builder->end_array();

    $builder->end_object();

    my $root = $builder->get_root();
    isa_ok($root, 'Glib::JSON::Node');
    is($root->get_node_type(), 'object', 'root holds an object');

    my $obj = $root->get_object();
    isa_ok($obj, 'Glib::JSON::Object');
    ok($obj->has_member('url'));
    is($obj->get_string_member('url'), 'http://www.gnome.org/img/flash/two-thirty.png');
    ok($obj->has_member('size'));
    is($obj->get_member('size')->get_node_type(), 'array');

    my $array = $obj->get_array_member('size');
    is($array->get_length(), 2);
    is($array->get_int_element(0), 652);
    is($array->get_int_element(1), 242);
}
