#!perl -T
#
# check if arrays serialize correctly
#

use strict;
use warnings;
use Test::More;
use Log::Message::JSON qw{msg};

eval "use JSON";
plan skip_all => "JSON required for decoding tests" if $@;

#-----------------------------------------------------------------------------

plan tests => 1;

#-----------------------------------------------------------------------------

my $expected = { array => [1, 2, 3] };
my $msg      = msg %$expected;
my $decoded  = decode_json("$msg");

is_deeply($decoded, $expected, "decoding a stringified array");

#-----------------------------------------------------------------------------
# vim:ft=perl
