#!perl -T
#
# test serialization of nested data structures
#

use strict;
use warnings;
#use Test::More tests => 4;
use Test::More;
use Log::Message::JSON qw{msg};

eval "use JSON";
plan skip_all => "JSON required for decoding tests" if $@;

#-----------------------------------------------------------------------------

plan tests => 4;

#-----------------------------------------------------------------------------

do {
  my $expected = { nested => { array => [1, 2, 3] } };
  my $msg      = msg %$expected;
  my $decoded  = decode_json("$msg");

  is_deeply($decoded, $expected, "decoding a nested array");
};

do {
  my $expected = { nested => { hash => { one => 1, two => 2 } } };
  my $msg      = msg %$expected;
  my $decoded  = decode_json("$msg");

  is_deeply($decoded, $expected, "decoding a nested hash");
};

do {
  my $expected =     { nested =>    { one => 1, two => 2 } };
  my $msg      = msg { nested => msg( one => 1, two => 2 ) };
  my $decoded  = decode_json("$msg");

  is_deeply($decoded, $expected, "decoding a nested Log::Message::JSON");
};

do {
  my $expected =     { nested =>    { one => 1, two => 2 } };
  my $msg      = msg { nested => msg  one => 1, two => 2   };
  my $decoded  = decode_json("$msg");

  is_deeply($decoded, $expected, "decoding a nested Log::Message::JSON (skipped parentheses)");
};

#-----------------------------------------------------------------------------
# vim:ft=perl
