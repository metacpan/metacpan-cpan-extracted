#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Test::More;

(my $vol, my $dir, undef) = File::Spec->splitpath(File::Spec->rel2abs($0));
require File::Spec->catpath($vol, $dir, 'sub_count.pl');

# TEST SCOPE: These tests exercise the use of pre-compiled regexen in import()

# Record the list of all %ENV keys that are valid as identifiers
my @valid = sort grep(/^[A-Za-z_]\w*$/, keys %ENV);
# Bucket them by first character
my %buckets;
for (@valid) { push(@{$buckets{substr($_, 0, 1)}}, $_); }
# Get the largest bucket
my $letter = (sort { $#{$buckets{$b}} <=> $#{$buckets{$a}} } keys %buckets)[0];

my $namespace = 'namespace0000';

# We needed the above information before knowing how many tests we would have:
plan tests => 2 + @{$buckets{$letter}};

my $code = <<"END_CODE";
package $namespace;
use Env::Export qr/^$letter/;
package main;
END_CODE

$code .= "is(${namespace}::$_(), \$ENV{$_}, '/^$letter/ regex, key=$_');\n"
    for (@{$buckets{$letter}});

# First set of tests: a sub-set of the environment based on a one-letter regex
eval $code;
warn "eval fail: $@" if $@;
# Check the count of exported symbols
is(sub_count($namespace), scalar(@{$buckets{$letter}}),
   "Number of subs exported to first namespace");

# Try a regex that would match an existing but invalid env key
$ENV{'***'} = '+++';
$namespace++;
eval "package $namespace; use Env::Export qr/\\W+/;";
warn "eval fail: $@" if $@;
is(sub_count($namespace), 0, 'Bad regex prevented from exporting subs');

exit;
