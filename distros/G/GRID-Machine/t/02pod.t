#!/usr/bin/perl -w
use strict;
use Test::More;
eval <<EOI;
use Test::Pod;
EOI
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
my @poddirs;
if (-r 'lib') {
  @poddirs = qw( blib lib examples);
}
elsif (-r '../lib') {
  @poddirs = qw( ../lib ../blib ../examples);
}
else {
  plan skip_all => "don't know where directory I am";
}
all_pod_files_ok( all_pod_files( @poddirs ) );

