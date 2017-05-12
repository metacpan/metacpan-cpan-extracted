#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Math::Aronson;
use Test;
BEGIN {
  plan tests => 2;
}

# uncomment this to run the ### lines
#use Smart::Comments;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

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
my $skip = ($have_threads
            ? undef
            : "due to threads.pm not available");

sub numeq_array {
  my ($a1, $a2) = @_;
  while (@$a1 && @$a2) {
    if ($a1->[0] ne $a2->[0]) {
      return 0;
    }
    shift @$a1;
    shift @$a2;
  }
  return (@$a1 == @$a2);
}

# This is only meant to check that any CLONE() done by threads works with
# the fields in the iterator object.  Being all-perl it's going to be fine.

my $it = Math::Aronson->new;
$it->next;

sub foo {
  return [ $it->next, $it->next, $it->next, $it->next ];
}
my $thread_got = [];
if ($have_threads) {
  my $threads_class = 'threads';
  my $thr = $have_threads && $threads_class->create(\&foo);
  $thread_got = $thr->join;
}
### $thread_got

my $want = [4, 11, 16, 24];
skip ($skip,
      numeq_array ($thread_got, $want),
      1,
      'same in thread as main');

my @main_got = ($it->next, $it->next, $it->next, $it->next);
### @main_got
skip ($skip,
      numeq_array (\@main_got,
                   [4, 11, 16, 24]),
      1,
      "thread doesn't upset main");

exit 0;
