#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;

use lib grep { -d } qw(./lib ../lib ./t/lib);
use Functional::Iterator;

sub all {
  my ($iterator) = @_;
  my @all;
  while (my $rec = $iterator->next) {
    push @all, $rec;
  }
  return @all;
}

my $numbers = iterator(records => [1..10]);
my $letters = iterator(records => ['a'..'z']);
my $multi = iterator(records => [$numbers, $letters]);

is_deeply( [all($numbers)], [1..10] );
is_deeply( [all($letters)], ['a'..'z'] );

is_deeply( [all($multi)], [] );
$multi->reset;
is_deeply( [all($multi)], [1..10, 'a'..'z'] );

my @list = (1..10);
my $shifty = iterator(generator => sub { shift @list });
is_deeply( [all($shifty)], [1..10] );

my @records = ('fnar', 'glar');
$multi = iterator(
  records => [
    iterator(records => [
      iterator(records => [qw(apple)], mutator => sub { uc(shift()) }),
      iterator(records => [qw(banana cherimoya)]),
    ]),
    iterator(records => [1,2,3], mutator => sub { shift() + 100 }),
    iterator(generator => sub { shift(@records) }),
  ],
);
is_deeply( [all($multi)], [qw(APPLE banana cherimoya 101 102 103 fnar glar)] );

my $empty = iterator(records => []);
is_deeply( [all($empty)], [] );
