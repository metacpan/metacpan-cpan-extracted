#!/usr/local/bin/perl

use v5.10;
use strict;
use warnings;

my $count = scalar(@_);

use Test::Harness qw(&runtests);

print "Count is $count\n";

my @tests = @_ > 0 ? "t/$_.t" : <t/*.t>;

runtests(@tests);
