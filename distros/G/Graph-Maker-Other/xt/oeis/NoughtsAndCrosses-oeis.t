#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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

use 5.005;  # for qr//
use strict;
use Test;
use List::Util;
plan tests => 9;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

require Graph::Maker::NoughtsAndCrosses;

# uncomment this to run the ### lines
# use Smart::Comments '###';


# A061530 Number of complete "rational" games of n X n tic-tac-toe: for n > 2 these are games that are a theoretical draw after each move.
# A181028 Number of n X n binary matrices that are completed draws in n-in-a-row tic-tac-toe, with 0 going first
# A181029 T(n,k)=Number of nXk binary matrices that are completed draws in min(n,k)-in-a-row tic-tac-toe, with 0 going first


my $re_2x2_winning_1 = qr/^(11
                          |..11
                          |1.1
                          |.1.1
                          |1..1
                          |.11)/x;
my $re_2x2_winning_2 = qr/^(22
                          |..22
                          |2.2
                          |.2.2
                          |2..2
                          |.22)/x;

my $re_3x3_winning_1 = qr/^(111
                          |...111
                          |......111
                          |1..1..1
                          |.1..1..1
                          |..1..1..1
                          |1...1...1
                          |..1.1.1)/x;
my $re_3x3_winning_2 = qr/^(222
                          |...222
                          |......222
                          |2..2..2
                          |.2..2..2
                          |..2..2..2
                          |2...2...2
                          |..2.2.2)/x;
my $re_3x3_winning = qr/$re_3x3_winning_1|$re_3x3_winning_2/o;

sub is_winning_1 {
  my ($v) = @_;
  if (length($v) == 1) {
    return $v eq '1';
  }
  if (length($v) == 4) {
    return $v =~ $re_2x2_winning_1;
  }
  if (length($v) == 9) {
    return $v =~ $re_3x3_winning_1;
  }
  die "cannot test is_winning_1 on $v";
}
sub is_winning_2 {
  my ($v) = @_;
  if (length($v) == 1) {
    return $v eq '2';
  }
  if (length($v) == 4) {
    return $v =~ $re_2x2_winning_2;
  }
  if (length($v) == 9) {
    return $v =~ $re_3x3_winning_2;
  }
  die "cannot test is_winning_2 on $v";
}
sub is_winning {
  my ($v) = @_;
  return is_winning_1($v) || is_winning_2($v);
}

my $re_complete = qr/^[12]*$/;

sub is_draw {
  my ($v) = @_;
  return $v =~ $re_complete && ! is_winning_1($v) && ! is_winning_2($v);
}


#------------------------------------------------------------------------------
# A087074  vertices at depth for N^2 players up to rotate and reflect

MyOEIS::compare_values
  (anum => 'A087074',
   max_count => 17,    # maximum 3x3
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       ### $N
       ### @got
       my $graph = Graph::Maker->new ('noughts_and_crosses',
                                      N=>$N, players => $N**2,
                                      rotate => 1, reflect => 1);
       my @pending = $graph->predecessorless_vertices;
       while (@pending && @got < $count) {
         push @got, scalar(@pending);
         @pending = List::Util::uniq(map {$graph->successors($_)} @pending);
       }
     }
     return \@got;
   });

# A085698 vertices in N^2 players, up to rotate and reflect
# 1,2,10,123310
MyOEIS::compare_values
  (anum => 'A085698',
   max_count => 4,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new ('noughts_and_crosses',
                                      N=>$N, players => $N**2,
                                      rotate => 1, reflect => 1);
       my $num_vertices = $graph->vertices;
       push @got, $num_vertices;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A048245  number of winning game states 3x3 up to rotation and reflection,
#          after n moves

MyOEIS::compare_values
  (anum => 'A048245',
   func => sub {
     my ($count) = @_;
     my $graph = Graph::Maker->new ('noughts_and_crosses',
                                    rotate => 1, reflect => 1);
     my @got;
     my @pending = ('000000000');
     while (@pending) {
       push @got, scalar(grep {$graph->is_successorless_vertex($_)} @pending);
       @pending = List::Util::uniq(map {$graph->successors($_)} @pending);
     }
     return \@got;
   });



#------------------------------------------------------------------------------
# A061529 number of games ending in draw
# eg. 3x3 has 46080 ways to draw

MyOEIS::compare_values
  (anum => 'A061529',
   max_count => 3,
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $N (1 .. $count) {
       my $graph = Graph::Maker->new ('noughts_and_crosses', N=>$N);
       my $games = 0;
       my $recurse;
       $recurse = sub {
         my ($v,$depth) = @_;
         if (my @successors = $graph->successors($v)) {
           foreach my $s (@successors) {
             $recurse->($s,$depth+1);
           }
         } elsif (is_draw($v)) {
           $games++;
         }
       };
       $recurse->($graph->predecessorless_vertices,-1);
       push @got, $games;
     }
     return \@got;
   });

# A061528 complete games won by O
MyOEIS::compare_values
  (anum => 'A061528',
   max_count => 3,
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $N (1 .. $count) {
       my $graph = Graph::Maker->new ('noughts_and_crosses', N=>$N);
       my $games = 0;
       my $recurse;
       $recurse = sub {
         my ($v,$depth) = @_;
         if (my @successors = $graph->successors($v)) {
           foreach my $s (@successors) {
             $recurse->($s,$depth+1);
           }
         } elsif (is_winning_2($v)) {
           $games++;
         }
       };
       $recurse->($graph->predecessorless_vertices,-1);
       push @got, $games;
     }
     return \@got;
   });

# A061527 complete games won by X
MyOEIS::compare_values
  (anum => 'A061527',
   max_count => 3,
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $N (1 .. $count) {
       my $graph = Graph::Maker->new ('noughts_and_crosses', N=>$N);
       my $games = 0;
       my $recurse;
       $recurse = sub {
         my ($v,$depth) = @_;
         if (my @successors = $graph->successors($v)) {
           foreach my $s (@successors) {
             $recurse->($s,$depth+1);
           }
         } elsif (is_winning_1($v)) {
           $games++;
         }
       };
       $recurse->($graph->predecessorless_vertices,-1);
       push @got, $games;
     }
     return \@got;
   });

# A061526 complete games
#         num paths from root to successorless
MyOEIS::compare_values
  (anum => 'A061526',
   max_count => 3,
   func => sub {
     my ($count) = @_;
     my @got;
     foreach my $N (1 .. $count) {
       my $graph = Graph::Maker->new ('noughts_and_crosses', N=>$N);
       my $games = 0;
       my $recurse;
       $recurse = sub {
         my ($v,$depth) = @_;
         if (my @successors = $graph->successors($v)) {
           foreach my $s (@successors) {
             $recurse->($s,$depth+1);
           }
         } else {
           $games++;
         }
       };
       $recurse->($graph->predecessorless_vertices,-1);
       push @got, $games;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A061221  number of winning game states 3x3, after n moves

MyOEIS::compare_values
  (anum => 'A061221',
   func => sub {
     my ($count) = @_;
     my $graph = Graph::Maker->new ('noughts_and_crosses', N=>3);

     my @got = (0) x 5;
     my $recurse;
     $recurse = sub {
       my ($v,$depth) = @_;
       if (my @successors = $graph->successors($v)) {
         foreach my $s (@successors) {
           $recurse->($s,$depth+1);
         }
       } elsif (is_winning($v)) {
         $got[$depth]++;
       }
     };
     $recurse->($graph->predecessorless_vertices,-1);

     # my @got = (0) x 9;
     # $graph->for_shortest_paths
     #   (sub {
     #      my ($trans, $u,$v) = @_;
     #      ### path: "$u $v"
     #      if ($u eq '0000' && $graph->is_successorless_vertex($v)) {
     #        my $distance = $trans->path_length($u,$v);
     #        $got[$distance]++;
     #        ### $distance
     #      }
     #    });

     # my @pending = ($graph->predecessorless_vertices);
     # while (@pending) {
     #   push @got, scalar(grep {$graph->is_successorless_vertex($_)} @pending);
     #   @pending = List::Util::uniq(map {$graph->successors($_)} @pending);
     # }

     return \@got;
   });

#------------------------------------------------------------------------------
# A008907  number of game states 3x3 up to rotation and reflection,
#          after n moves

MyOEIS::compare_values
  (anum => 'A008907',
   func => sub {
     my ($count) = @_;
     my $graph = Graph::Maker->new ('noughts_and_crosses',
                                    rotate => 1, reflect => 1);
     my @got;
     my @pending = ('000000000');
     while (@pending) {
       push @got, scalar(@pending);
       @pending = List::Util::uniq(map {$graph->successors($_)} @pending);

     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
