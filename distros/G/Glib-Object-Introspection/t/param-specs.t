#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;

plan tests => 7;

GI::param_spec_in_bool (Glib::ParamSpec->boolean ('mybool', 'mybool', 'mybool', Glib::FALSE, []));
pass;

my $ps1 = GI::param_spec_return;
isa_ok ($ps1, 'Glib::Param::String');
is ($ps1->get_name, 'test_param');
is ($ps1->get_default_value, '42');

my $ps2 = GI::param_spec_out;
isa_ok ($ps2, 'Glib::Param::String');
is ($ps2->get_name, 'test_param');
is ($ps2->get_default_value, '42');
