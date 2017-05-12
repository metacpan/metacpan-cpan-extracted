#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
use Lingua::EN::Tokenizer::Offsets qw/get_tokens/;
use utf8::all;
use Test::Differences;

my $original = "Meredith, Henry (17..-18..)";

my $expected = <<STREND
Meredith
,
Henry
(
17
..
-18
..
)
STREND
;

my $tokens = get_tokens($original);
my $got = join "\n",@$tokens;

eq_or_diff "$got\n",  $expected,   "testing weird string";


