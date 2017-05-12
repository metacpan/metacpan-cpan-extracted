#!/usr/bin/env perl
use strict;
use warnings;
use Test::Class::Moose::Load 't/lib';

my $test_suite = Test::Class::Moose->new(
    randomize    => 0,
    test_classes => \@ARGV,
);

$test_suite->runtests;
