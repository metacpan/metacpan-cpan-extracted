#!/usr/bin/env perl

# for feeding NYTProf

use strict; use warnings;

use Devel::Hide 'List::UtilsBy::XS';

use List::Objects::WithUtils;

my $arr = array 1 .. 1000;

sub main {
# bisect
  my $pair = $arr->bisect(sub { $_ >= 500 });
# copy
  my $copy = $arr->copy;
# count
  my $count = $arr->count;
# defined
  1 if $arr->defined(1);
# diff
  array(1 .. 3)->diff([ 5,4,3,2,1 ]);
# end
  my $lastidx = $arr->end;
# exists
  1 if $arr->exists(10);
# first_index
  my $firstidx = $arr->first_index(sub { $_ == 10 });
# first_where
  my $first = $arr->first_where(sub { $_ == 10 });
# flatten_all
  my $flat = array([1, 2, [ 3, 4 ] ])->flatten_all;
# flatten
  $flat = array(1, 2, [ 3, 4, [ 5, 6 ] ])->flatten(1);
  $flat = array(1, 2, [ 3, 4, [ 5, 6, [ 7, 8 ] ] ])->flatten(2);
# folds
  my $res = $arr->foldr(sub { $a + $b });
  $res = $arr->foldl(sub { $a + $b });
# get_or_else
  $res = $arr->get_or_else(9999 => sub { 1 });
# grep
  $res = $arr->grep(sub { $_ > 500 });
# has_any
  1 if $arr->has_any;
  1 if $arr->has_any(sub { $_ > 500 });
# head
  $res = $arr->head;
  my ($head, $tail) = $arr->head;
# indexes
  $res = $arr->indexes(sub { $_ > 500 });
# inflate
  my $hash = array(foo => 1, bar => 2, baz => 3)->inflate;
# intersection
  $res = array(qw/a b c d/)->intersection([qw/c d e f/]);
# items_after_incl
  $res = $arr->items_after_incl(sub { $_ > 500 });
# items_after
  $res = $arr->items_after(sub { $_ > 500 });
# items_before_incl
  $res = $arr->items_before_incl(sub { $_ > 500 });
# items_before
  $res = $arr->items_before(sub { $_ > 500 });
# join
  $res = $arr->join(' ');
# kv
  $res = $arr->kv;
# last_index
  $res = $arr->last_index(sub { $_ < 400 });
# last_where
  $res = $arr->last_where(sub { $_ < 400 });
# map
  $res = $arr->map(sub { $_ + 1 });
# mapval
  $res = $arr->mapval(sub { $_ + 1 });
# mesh
  $res = array(1 .. 4)->mesh(['a' .. 'd']);
# natatime
  my $itr = $arr->natatime(100);
  1 while $itr->();
# nsect
  $res = $arr->nsect(2);
# nsort_by
  $res = $arr->nsort_by(sub { $_ });
# part
  $res = $arr->part(sub { $_ & 1 });
# random
  $res = $arr->random;
# reverse
  $res = $arr->reverse;
# rotate_in_place
  $arr->rotate_in_place;
# rotate
  $res = $arr->rotate;
# shuffle
  $res = $arr->shuffle;
# sliced
  $res = $arr->sliced(1 .. 10);
# sort_by
  $res = $arr->sort_by(sub { $_ });
# sort
  $res = $arr->sort;
# splice
  $res = $arr->splice(2);
# ssect
  $res = $arr->ssect(3);
# tuples
  $res = $arr->tuples(2);
# uniq
  $res = array(1 .. 100, 1 .. 30)->uniq;
# visit
  $arr->visit(sub { $_++ });
}


main for 1 .. 10000;
