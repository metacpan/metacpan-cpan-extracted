#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
use Lingua::EN::Sentence::Offsets qw/get_sentences/;


my ($text,$expected,$got);

# github #2
$text     = "Is dr. Ahmed in his office ?";
$expected = [ "Is dr. Ahmed in his office ?" ];
$got      = Lingua::EN::Sentence::Offsets::get_sentences($text);

is_deeply($got,$expected,"Don't split after abbreviations (GitHub #2)");

