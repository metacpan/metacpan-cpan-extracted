#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;

use Test;
plan tests => 2;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Math::NumSeq::OEIS::File;

# uncomment this to run the ### lines
#use Smart::Comments;

my $skip;

my $have_threads;
use Config;
if (! $Config{useithreads}) {
  MyTestHelpers::diag ('Config no useithreads in this Perl');
} else {
  $have_threads = eval { require threads; 1 }; # new in perl 5.8, maybe
  if (! $have_threads) {
    MyTestHelpers::diag ("threads.pm not available -- $@");
  }
}

if (! $have_threads) {
  $skip = "due to threads.pm not available";
}

my $seq;
unless ($skip) {
  eval { $seq = Math::NumSeq::OEIS::File->new (anum => 'A000040') } # primes
    or $skip = $@;
}
MyTestHelpers::diag ('seq fh: ', $seq && $seq->{'fh'});

unless ($skip) {
  $seq->next;
  $seq->next;
  $seq->next;
}

sub foo {
  return ($seq
          ? [ $seq->next, $seq->next, $seq->next, $seq->next ]
          : []);
}
my $thread_got = [];
if ($have_threads) {
  my $threads_class = 'threads';
  my $thr = $have_threads && $threads_class->create(\&foo);
  $thread_got = $thr->join;
}
### $thread_got

my $want = ($skip ? [] : [4,7, 5,11, 6,13, 7,17]);
skip ($skip,
      join(',',@$thread_got),
      join(',',@$want),
      'same in thread as main');

my $main_got = foo();
skip ($skip,
      join(',',@$main_got),
      join(',',@$want),
      "thread doesn't upset main");

exit 0;
