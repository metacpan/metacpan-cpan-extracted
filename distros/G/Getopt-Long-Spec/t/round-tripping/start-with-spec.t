#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;

our ($BUILDER_CLASS, $PARSER_CLASS);

BEGIN {
  $BUILDER_CLASS = 'Getopt::Long::Spec::Builder';
  $PARSER_CLASS  = 'Getopt::Long::Spec::Parser';
  use_ok($BUILDER_CLASS);
  use_ok($PARSER_CLASS);
}

my @TEST_SPECS = (
    'foo|f!',
    'foo|f+',
    'foo|f=i',
    'foo|f:i',
    'foo|f:s',
    'foo',
    'foo|f|bar',
    '_foo|_bar',
    'foo|f',
    'foo|f:+',
    'foo|f:5',
    'foo|f|g|h',
    'bar|b=s@{1,}',
    'bar|b=s@{,5}',
    'bar|b=s%'
);


my $bo = new_ok($BUILDER_CLASS);
my $po = new_ok($PARSER_CLASS);

for my $orig_spec ( @TEST_SPECS ) {
    my $params = $po->parse( $orig_spec );
    my $new_spec = $bo->build( %$params );

    is $new_spec, $orig_spec, "round tripped spec [$orig_spec]"
     or diag Dumper $params;
}

done_testing;

