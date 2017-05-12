#!/usr/bin/perl

#
# Test the various things that deal with 64 bit integers.
#

use strict;
use warnings;
use Glib;
use Test::More tests => 12;

use constant {
  MIN_INT64 => "-9223372036854775807",
  MAX_INT64 => "9223372036854775807",

  MIN_UINT64 => "0",
  MAX_UINT64 => "18446744073709551615"
};

my $spec_int64 =
  Glib::ParamSpec -> int64("int64", "Int", "Blurb",
                           MIN_INT64, MAX_INT64, 0,
                           [qw/readable writable/]);
isa_ok($spec_int64, "Glib::Param::Int64");
is($spec_int64 -> get_minimum(), MIN_INT64);
is($spec_int64 -> get_maximum(), MAX_INT64);
is($spec_int64 -> get_default_value(), 0);

my $spec_uint64 =
  Glib::ParamSpec -> uint64("uint64", "UInt", "Blurb",
                            MIN_UINT64, MAX_UINT64, 0,
                            [qw/readable writable/]);
isa_ok($spec_uint64, "Glib::Param::UInt64");
is($spec_uint64 -> get_minimum(), MIN_UINT64);
is($spec_uint64 -> get_maximum(), MAX_UINT64);
is($spec_uint64 -> get_default_value(), 0);

Glib::Type -> register_object(
  'Glib::Object' => 'Foo',
  properties => [ $spec_int64, $spec_uint64 ]
);

my $foo = Foo -> new();

$foo -> set(int64 => MIN_INT64);
is($foo -> get("int64"), MIN_INT64);
$foo -> set(int64 => MAX_INT64);
is($foo -> get("int64"), MAX_INT64);

$foo -> set(uint64 => MIN_UINT64);
is($foo -> get("uint64"), MIN_UINT64);
$foo -> set(uint64 => MAX_UINT64);
is($foo -> get("uint64"), MAX_UINT64);
