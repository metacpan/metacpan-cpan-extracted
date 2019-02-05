#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;

plan tests => 7;

SKIP: {
  skip 'param spec in test', 1
    unless check_gi_version (1, 35, 4);

  GI::param_spec_in_bool (Glib::ParamSpec->boolean ('mybool', 'mybool', 'mybool', Glib::FALSE, []));
  pass;
}

SKIP: {
  skip 'param spec return tests', 6
    unless check_gi_version (1, 33, 10);

  my $ps1 = GI::param_spec_return ();
  isa_ok ($ps1, 'Glib::Param::String');
  is ($ps1->get_name, 'test_param');
  is ($ps1->get_default_value, '42');

  my $ps2 = GI::param_spec_out ();
  isa_ok ($ps2, 'Glib::Param::String');
  is ($ps2->get_name, 'test_param');
  is ($ps2->get_default_value, '42');
}
