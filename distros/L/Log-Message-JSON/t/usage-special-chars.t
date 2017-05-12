#!perl -T
#
# test if special characters (backslash, quotes, newlines, tabs) are quoted
# properly
#

use strict;
use warnings;
#use Test::More tests => 4;
use Test::More;
use Log::Message::JSON qw{msg};

eval "use JSON";
plan skip_all => "JSON required for decoding tests" if $@;

#-----------------------------------------------------------------------------

plan tests => 1;

#-----------------------------------------------------------------------------

my $expected = {
  tab => "\t",
  newline => "\n",
  CR => "\r",
  backslash => "\\",
  single_quote => "'",
  double_quote => '"',
  more_complex_string => '\"foo bar\"',
};
my $msg      = msg %$expected;
my $msg_str  = "$msg";
my $decoded  = decode_json($msg_str);

is_deeply($decoded, $expected, "decoding JSON with backslash characters");

#-----------------------------------------------------------------------------
# vim:ft=perl
