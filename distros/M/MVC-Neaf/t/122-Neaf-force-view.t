#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;
neaf->set_forced_view("Dumper");

is( ref neaf->get_view("TT"), "MVC::Neaf::View::Dumper", "force view");
is( ref neaf->get_view("Custom"), "MVC::Neaf::View::Dumper", "force view 2");

is_deeply( [neaf->get_view("JS")->render({-template=>"Foo"})]
    , [ "\$VAR1 = {\n  '-template' => 'Foo'\n};\n", "text/plain"]
    , "View actually works");

done_testing;
