#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;

plan tests => 3;

{
  my $wrapper = Glib::Object::Introspection::GValueWrapper->new ('Glib::Int', 23);
  is (Regress::test_int_value_arg ($wrapper), 23);
}

is (Regress::test_value_return (23), 23);

SKIP: {
  skip 'more GValue tests', 1
    unless check_gi_version (1, 38, 0);

  my $wrapper = Glib::Object::Introspection::GValueWrapper->new ('Glib::Int', 42);
  GI::gvalue_in_with_modification ($wrapper);
  is ($wrapper->get_value, 24);
}
