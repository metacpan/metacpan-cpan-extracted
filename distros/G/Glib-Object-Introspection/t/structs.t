#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;

plan tests => 6;

SKIP: {
  skip 'new stuff', 2
    unless check_gi_version (0, 12, 0);
  my $expected_struct = {long_ => 6, int8 => 7};
  my $struct = GI::SimpleStruct::returnv ();
  is_deeply ($struct, $expected_struct);
  GI::SimpleStruct::inv ($struct);
  GI::SimpleStruct::method ($struct);
  undef $struct;
  is_deeply (GI::SimpleStruct::returnv (), $expected_struct);
}

SKIP: {
  skip 'new stuff', 2
    unless check_gi_version (0, 12, 0);
  my $expected_struct = {long_ => 42};
  my $struct = GI::PointerStruct::returnv ();
  is_deeply ($struct, $expected_struct);
  GI::PointerStruct::inv ($struct);
  undef $struct;
  is_deeply (GI::PointerStruct::returnv (), $expected_struct);
}

{
  my $expected_struct = {
    some_int => 23, some_int8 => 42, some_double => 11, some_enum => 'value1'};
  is_deeply (Regress::TestStructA::clone ($expected_struct), $expected_struct);
}

{
  my $expected_struct = {
    some_int8 => 32,
    nested_a => {
      some_int => 23, some_int8 => 42,
      some_double => 11, some_enum => 'value1'}};
  is_deeply (Regress::TestStructB::clone ($expected_struct), $expected_struct);
}
