#!perl
############ STANDARD Pod::Coverage TEST - DO NOT EDIT ##################
use Test::More;
use strict;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;
all_pod_coverage_ok({ 
  coverage_class => 'Pod::Coverage::CountParents',
  also_private => [ qr/\A has_ /x],
});
