#! /usr/bin/env perl
use strict;
use warnings;
no warnings 'once', 'redefine';
use Test::More;
use List::Util qw(pairs unpairs);
use Scalar::Util 'weaken';
use Data::Printer;

use Exporter::Handy::Util xtags => { -as => 'xtags_standard' };
use Exporter::Handy::Util xtags => { -as => 'xtags_prefixed',  sig => ':' };

sub test_deeply {
  my ($function, $params, $expected, $label) = @_;

  my @got = $function->(@{; $params // [] });

  # say STDERR;
  # say STDERR 'Expected: ' . np(@$expected);
  # say STDERR 'Got     : ' . np(@got);
  # say STDERR;

  is_deeply( \@got, $expected, $label // () );
}

my @cases = (
  {
    params           => [ foo    => [qw(f1 f2)] ],
    expect           => [ foo    => [qw(f1 f2)] ],
  },
  {
    params           => [ g1 => { foo    => [qw(f1 f2)] } ],
    expect           => [ g1 => [qw(:g1_foo)], g1_foo    => [qw(f1 f2)] ],
  },
  {
    params           => [ g1 => { g2 => { foo    => [qw(f1 f2)] } } ],
    expect           => [ g1 => [qw(:g1_g2 :g1_g2_foo)], g1_g2 => [qw(:g1_g2_foo)], g1_g2_foo => [qw(f1 f2)] ],
  },
);

for (@cases) {
  my @expect_1 = @{; $_->{expect} };
  my @expect_2 = map { (':' . $_->[0], $_->[1]) } pairs(@expect_1);
  test_deeply(\&xtags_standard, $_->{params}, \@expect_1);
  test_deeply(\&xtags_prefixed, $_->{params}, \@expect_2);
}

done_testing;