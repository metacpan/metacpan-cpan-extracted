#!perl -T
#
# test if JSON-ification creates single line
#

use strict;
use warnings;
#use Test::More tests => 4;
use Test::More;
use Log::Message::JSON qw{msg};

eval "use JSON";
plan skip_all => "JSON required for decoding tests" if $@;

#-----------------------------------------------------------------------------

plan tests => 2;

#-----------------------------------------------------------------------------

my $multiline_string = "first line
second line
  indented third line

fourth line after empty line
";

my $expected = { string => $multiline_string };
my $msg      = msg %$expected;
my $msg_str  = "$msg";
my $decoded  = decode_json($msg_str);

my @lines = split /\n/, $msg_str, -1;
is(scalar(@lines), 1, "number of lines in stringified message == 1");

is_deeply($decoded, $expected, "decoding JSON with multiline string");

#-----------------------------------------------------------------------------
# vim:ft=perl
