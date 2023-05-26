#! /usr/bin/env perl
use strict;
use warnings;
no warnings 'once', 'redefine';
use Test::More;
use Data::Printer;

our (%EXPORT_TAGS); # Should be automagically filled by export().
use Exporter::Handy -exporter_setup => 1;

export(
  qw(foo1 foo2),
  ':tag1' => [qw(foo1 foo2)],
);

sub foo1 {};
sub foo2 {};


my %expected=(
  EXPORT_TAGS => {
      default => [],
      tag1    => [qw(foo1 foo2)],
  },
);

is_deeply(\%EXPORT_TAGS, $expected{EXPORT_TAGS}, 'Check if EXPORT_TAGS is correctly filled');

done_testing;