#!/usr/bin/perl
use Test::More tests => 2;
BEGIN { use_ok('Lingua::Identify', qw/:language_identification/) };

is_deeply( [ get_all_methods ],   [ qw/smallwords prefixes1 prefixes2 prefixes3
				prefixes4 suffixes1 suffixes2 suffixes3
				suffixes4 ngrams1 ngrams2 ngrams3 ngrams4/ ] );
