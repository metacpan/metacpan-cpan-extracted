#!/usr/bin/perl -w

# Copyright 2021 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use 5.004;
use List::Util 'sum';
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 110;

use FindBin;
use lib "$FindBin::Bin/../..";

# uncomment this to run the ### lines
# use Smart::Comments;

require Graph::Maker::FibonacciCube;


#------------------------------------------------------------------------------
{
  my $want_version = 19;
  ok ($Graph::Maker::FibonacciCube::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::FibonacciCube->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::FibonacciCube->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::FibonacciCube->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# Helpers

sub Fibonacci {
  my ($n) = @_;
  my ($x,$y) = (0,1);
  foreach (1 .. $n) { ($x,$y) = ($y,$x+$y); }
  return $x;
}
{
  my @want = (0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55);
  foreach my $n (0 .. $#want) {
    ok (Fibonacci($n), $want[$n], "Fibonacci()");
  }
}

sub Lucas {
  my ($n) = @_;
  my ($x,$y) = (2,1);
  foreach (1 .. $n) { ($x,$y) = ($y,$x+$y); }
  return $x;
}
{
  my @want = (2, 1, 3, 4, 7, 11, 18, 29, 47, 76, 123);
  foreach my $n (0 .. $#want) {
    ok (Lucas($n), $want[$n], "Lucas()");
  }
}

ok (rindex('abcd','b'), 1);
ok (rindex('abcdb','b'),       4);
ok (rindex('abcdb','b',4),     4);
ok (rindex('abcdb','b',3),     1);

#------------------------------------------------------------------------------
# _fibbinary_next()

ok (Graph::Maker::FibonacciCube::_fibbinary_next('00000'), '00001');
ok (Graph::Maker::FibonacciCube::_fibbinary_next('000101'), '001000');
ok (Graph::Maker::FibonacciCube::_fibbinary_next('101010'), undef);
ok (Graph::Maker::FibonacciCube::_fibbinary_next('101000'), '101001');
ok (Graph::Maker::FibonacciCube::_fibbinary_next('101001'), '101010');

sub is_Fibbinary {
  my ($str) = @_;
  return $str !~ /11/;
}
{
  my $bad = 0;
  foreach my $len (4) {
    my $want = '0' x $len;
    foreach my $n (0 .. 2**$len-1) {
      my $str = sprintf '%0*b', $len, $n;
      ### is_Fibbinary(): is_Fibbinary($str)
      ### $str
      ### $want
      if (is_Fibbinary($str)) {
        unless ($want eq $str) { $bad++; }
        $want = Graph::Maker::FibonacciCube::_fibbinary_next($want,0);
      } else {
        unless (! defined($want) || $want ne $str) { $bad++; }
      }
    }
    ok ($want, undef);
  }
  ok ($bad, 0);
}

sub is_Lucas {
  my ($str) = @_;
  $str .= $str;
  return $str !~ /11/;
}
{
  my $bad = 0;
  foreach my $len (4) {
    my $want = '0' x $len;
    foreach my $n (0 .. 2**$len-1) {
      my $str = sprintf '%0*b', $len, $n;
      ### is_Lucas(): is_Lucas($str)
      ### $str
      ### $want
      if (is_Lucas($str)) {
        unless ($want eq $str) { $bad++; }
        $want = Graph::Maker::FibonacciCube::_fibbinary_next($want,1);
      } else {
        unless (! defined($want) || $want ne $str) { $bad++; }
      }
    }
    ok ($want, undef);
  }
  ok ($bad, 0);
}
  

#------------------------------------------------------------------------------
# Lucas Cubes

{
  my $N = 0;
  my $graph = Graph::Maker->new('Fibonacci_cube',
                                N => $N,
                                Lucas => 1);
  my @vertices = sort $graph->vertices;
  ok (scalar(@vertices), 1);
  ok (join(',',@vertices), '');
}
{
  my $N = 1;
  my $graph = Graph::Maker->new('Fibonacci_cube',
                                N => $N,
                                Lucas => 1);
  my @vertices = sort $graph->vertices;
  ok (scalar(@vertices), 1);
  ok (join(',',@vertices), '0');
}

{
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Fibonacci_cube',
                                  N => $N,
                                  Lucas => 1,
                                  undirected => 1);
    ok (scalar($graph->vertices), Lucas($N),
        "Lucas cube num vertices, N=$N");

    foreach my $v ($graph->vertices) {
      ok (is_Lucas($v) ? 1 : 0, 1);
    }
  }
}

#------------------------------------------------------------------------------
# Fibonacci Cubes

{
  foreach my $N (0 .. 7) {
    my $graph = Graph::Maker->new('Fibonacci_cube', N => $N,
                                  undirected => 1);
    ok (scalar($graph->vertices), Fibonacci($N+2));

    foreach my $v ($graph->vertices) {
      ok (is_Fibbinary($v) ? 1 : 0, 1);
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
