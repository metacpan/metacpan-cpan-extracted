#!/usr/bin/perl
require 5;
package Games::Alak;
use strict;
use vars qw($Tree $Term $Max_depth $VERSION);
$VERSION = '0.19';
# BEGIN {$^W = 1}; # warnings on

use constant BOARD_SIZE => 11;
use constant ENDGAME  => 1000;
die( "Board_size " , BOARD_SIZE, " is too small!") if BOARD_SIZE < 9;

use constant NEW_BOARD_STRING =>
 ('xxxx' . ('.' x (BOARD_SIZE - 8)) . 'oooo');

#--------------------------------------------------------------------------

sub play {
  my($x_best_move, @o_move_chosen, $from, $to);
  
  $Max_depth = 3; # must be an integer > 0
  $Tree = _new_node(NEW_BOARD_STRING, 'x', -1,-10,0);
  
  use Term::ReadLine;
  $Term = Term::ReadLine->new('Alak');
  my $out = $Term->OUT;
  select($out) if $out;

  print "Lookahead set to $Max_depth.  I am X, you are O.\n";
  print "Enter h for help\n";
  
 Main_loop:
  while(1) {
    grow($Tree);
    $x_best_move = optimal_move($Tree, 'x');

    die "No X move possible?!" unless $x_best_move;
    $Tree = $x_best_move;  # select that node

    printf "X moves from %s to %s, yielding %s\n",
      1 + $Tree->{'last_move_from'},
      1 + $Tree->{'last_move_to'},
      $Tree->{'board'};
    
    if($Tree->{'endgame'}) {
      print "Endgame.  X wins after ",
         $Tree->{'move_count'}, " moves.\n";
      last;
    }
    grow($Tree) unless @{$Tree->{'successors'}};

   Get_move:
    {
      ($from, $to) = prompt_for_next_move();
      --$from; # we index from 0, not 1
      --$to;
      
      # check legality
      @o_move_chosen =
        grep $_->{'last_move_from'} eq $from &&
             $_->{'last_move_to'}   eq $to,
            @{$Tree->{'successors'}};
      if(@o_move_chosen > 1) {
        die "PANIC!? ", $Tree->{'board'};
      } elsif(@o_move_chosen == 0) {
        print "Invalid move!\n";
        redo Get_move;
      } else {
        # That move designates just one successor
        $Tree = $o_move_chosen[0];  # select that node.
      }
    }        

    printf "O moves from %s to %s, yielding %s\n",
      1 + $Tree->{'last_move_from'},
      1 + $Tree->{'last_move_to'},
      $Tree->{'board'};

    if($Tree->{'endgame'}) {
      print "Endgame.  O wins after ",
         $Tree->{'move_count'}, " moves.\n";
      last;
    }
  }
}

#--------------------------------------------------------------------------

sub prompt_for_next_move { # prompting
  my $line;
  while(defined($line = $Term->readline('alak>'))) {
    $line =~ s/^\s+//s;
    $line =~ s/\s+$//s;
    next unless length($line);
    $Term->addhistory($line);

    # Knuckle-headed command parsing:

    if($line =~ m/^q/s) {
      last;  # quit
    } elsif($line =~ m/^(\d+)\s*to\s*(\d+)$/s) {
      return($1, $2);
    } elsif($line =~ m/^g(?:row)?$/s) {
      grow($Tree);
      print "Tree grown.\n";
    } elsif($line eq 'reset') {
      $Tree = _new_node(NEW_BOARD_STRING, 'o', -1,-1,0,0);
      grow($Tree);
      print "Board reset to ", NEW_BOARD_STRING, "\nYour move.\n";
    } elsif($line =~ m/^reset\s+([.ox]+)/s) {
      my $board = $1;
      if(length($board) != BOARD_SIZE) {
        print "But a board has to be ", BOARD_SIZE, " wide, not ",
          length($board), "\n";
      } elsif($board !~ m/\./s) {
        print "But there's no spaces on board $board\n";
      } elsif(($board =~ tr/x//) < 2) {
        print "But there's fewer than two x's in board $board\n";
      } elsif(($board =~ tr/o//) < 2) {
        print "But there's fewer than two o's in board $board\n";
      } else {
        $Tree = _new_node($board, 'o',-1,-1,0,0);
        grow($Tree);
        print "Board reset to $board\nYour move.\n";
      }
    } elsif($line =~ m/^d(?:ump)?\s*(\d+)?$/s) {
      dump_tree($Tree, defined($1) ? ($1 + 1) : undef);
    } elsif($line eq 'advise' or $line eq 'advice') {
      my $m = optimal_move($Tree,'o');
      printf "Try %d to %d.\n",
        1 + $m->{'last_move_from'},
        1 + $m->{'last_move_to'},
      ;
    } elsif($line =~ m/l(?:ookahead)?\s+([1-9]+)$/s) {
      $Max_depth = $1;
      print "Lookahead set to $1.\n";
    } elsif($line =~ m/^h/s) {
      print
        "Commands:\n",
        "  q -- quit\n",
        "  dump N -- dump game tree to depth N.\n",
        "  lookahead N -- set tree-deepening depth to N.\n",
        "  advise -- have me suggest a move.\n",
        "  reset -- start anew.\n",
        "  reset xxx.o.x..oo -- start anew from the board specified.\n",
        "  N to N -- move piece from N to N.\n",
        "  h -- help (this message)\n",
        "\n",
    } else {
      print "Unknown command.  Enter h for help.\n";
    }
  }

  # Either we got undef back, or lasted out from 'q'
  print "Quitting.\n";
  exit;
}
  
#--------------------------------------------------------------------------

sub _new_node {
  return
    {
     'board'          => $_[0],
     'whose_turn'     => $_[1],
     'last_move_from' => $_[2], 
     'last_move_to'   => $_[3],
     'last_move_payoff' => $_[4],
      # payoff to x, that is.
     'move_count' => $_[5],
     'successors' => [],
    };
}

#--------------------------------------------------------------------------

sub grow {
  my $n = $_[0];
  my $depth = $_[1] || 0;
  figure_successors($n)
   unless
    $depth >= $Max_depth
    or @{$n->{'successors'}}
    or $n->{'endgame'};
  
  if(@{$n->{'successors'}}) {
    my $a_payoff_sum = 0;
    foreach my $s (@{$n->{'successors'}}) {
      grow($s, $depth + 1);  # RECURSE
      $a_payoff_sum += $s->{'average_payoff'};
    }
    $n->{'average_payoff'} =
      $a_payoff_sum / @{$n->{'successors'}};
  } else {
    $n->{'average_payoff'} = $n->{'last_move_payoff'};
  }
}

#--------------------------------------------------------------------------

sub optimal_move {
  my($board, $mover) = @_;
  # given a board (node), return the successors that are the
  #   best for the mover.
  # (in scalar context, randomly choose from
  #  the best ones, if there's a tie for first place)

  my @best_cases;  
  foreach my $c (@{$board->{'successors'}}) {
    my $this_payoff = $c->{'average_payoff'};
    if(!@best_cases  # nothing seen yet
       or $best_cases[0]{'average_payoff'} == $this_payoff
         # tie for first place so far
    ) {
      push @best_cases, $c;
    } elsif(
        $mover eq 'x' # does 'best' mean HIGH payoff?
        ? ($this_payoff > $best_cases[0]{'average_payoff'}) # max!
        : ($this_payoff < $best_cases[0]{'average_payoff'}) # min!
    ) {
        @best_cases = ($c);
    }
     # otherwise what's there is not as good as what we've got
  }
  return $best_cases[0] if @best_cases == 1; # no tie
  return $best_cases[rand @best_cases] if @best_cases;
  return undef;  # shouldn't ever happen!
}


#--------------------------------------------------------------------------

{
  my($depth, $census, $max_depth_seen, $show_to_depth);
  
  sub dump_tree {
    # wrapper around _dump_recursor
    my $starting_node;
    ($starting_node, $show_to_depth) = @_;
    # initialize things
    $depth = $census = $max_depth_seen = 0;
    _dump_recursor($starting_node);
    printf "%d in tree of depth %d (branching factor %.2f)\n",
      $census, $max_depth_seen, 
      $census ** (1/($max_depth_seen || 1)),
    ;
  }
  
  sub _dump_recursor {
    my $n = $_[0];
    
    ++$census;
    $max_depth_seen = $depth if $depth > $max_depth_seen;
    printf "  %s%s    %s %2s to %2s %s %s %s\n",
      ' : ' x $depth, # indenting
      $n->{'board'},
      $n->{'whose_turn'} eq 'o' ? 'x' : 'o',
      # Count places on the board starting at 1:
      1 + $n->{'last_move_from'},
      1 + $n->{'last_move_to'},
      omit_if_zero('Immediate score = ', $n->{'last_move_payoff'}),
      omit_if_zero('Avg score = ', $n->{'average_payoff'}),
      $n->{'endgame'} ? 'endgame' : '',
     unless defined($show_to_depth) and $show_to_depth <= $depth;
    
    if(@{$n->{'successors'}}) {
      ++$depth;
      foreach my $s (@{$n->{'successors'}}) {
        _dump_recursor($s);
      }
      --$depth;
    }
    
    return;
  }
}

sub omit_if_zero {
  return '' unless $_[1];
  return join(' ', $_[0], substr($_[1],0,5));
}

#--------------------------------------------------------------------------

sub figure_successors {  # ...of a given node
  die "I need a board!" unless ref $_[0] eq 'HASH';
  my $node = $_[0];
  return if $node->{'endgame'}
   or $node->{'board'} =~ tr/x// < 2
   or $node->{'board'} =~ tr/o// < 2;

  my $board = $node->{'board'};
  my $mover = $node->{'whose_turn'};
  my $other;
  if($mover eq 'x') { $other = 'o' }
  elsif ($mover eq 'o') { $other = 'x' }
  else {die "Mover \"$mover\" is neither x nor o!"; }

  my $successors = $node->{'successors'};
  die "I already figured successors for this!?" if @$successors;

  my $this_move_count = 1 + ($node->{'move_count'} || 0);

  foreach(my $i = 0; $i < BOARD_SIZE; $i++) {
    next unless substr($board,$i,1) eq $mover;

    # Find the first blanks to the left and
    #  to the right of the current piece
    foreach my $to (
      rindex($board,'.',$i-1),
       index($board,'.',$i+1),
    ) {
      next if $to == -1;
       # if no move possible in this direction

      my $new_board = $board;
      substr($new_board, $i, 1) = '.'; # move from...
      substr($new_board, $to,1) = $mover; # ...to

      my $payoff = 0;

      # Now see if a move from $i to $to deletes nonmover's pieces!
      # Look for mover's piece and other pieces in the part of
      #  the board that's to my left, and my right.
      # (This is the only really scary code in this program.  Honest!)
      $payoff += length $1   # look to the left
       if $to > 1 and
        $mover eq 'o'
         ? substr($new_board,0,$to) =~ s/o(x+)$/'o' . ('.' x length $1)/se
         : substr($new_board,0,$to) =~ s/x(o+)$/'x' . ('.' x length $1)/se;
      $payoff += length $1   # look to the right
       if $to < BOARD_SIZE - 2 and
        $mover eq 'o'
         ? substr($new_board,$to+1) =~ s/^(x+)o/('.' x length $1) . 'o'/se
         : substr($new_board,$to+1) =~ s/^(o+)x/('.' x length $1) . 'x'/se;

      # Exaggerate payoff if $mover wins
      my $is_endgame;
      if( grep($_ eq $other, split '', $new_board) < 2 ) {
        $payoff = ENDGAME;
        $is_endgame = 1;
      }
      $payoff = 0 - $payoff if $mover eq 'o';
         # harming X is a /negative/ payoff

      push @$successors,
        _new_node(
          $new_board,
          $other, # it's other guy's turn now
          $i,
          $to,
          $payoff,
          $this_move_count,
        );
      $successors->[-1]{'endgame'} = 1 if $is_endgame;
       # THAT node shouldn't have successors
    }
  }
  return;
}

#--------------------------------------------------------------------------
play() unless caller;
 # if this module is what was run (instead of used), then start game

#--------------------------------------------------------------------------
1;

__END__


=head1 NAME

Games::Alak -- simple game-tree implementation of a gomoku-like game

=head1 SYNOPSIS

  % perl -MGames::Alak -e Games::Alak::play
   ...Or just run Alak.pm as if it were a program...
   ...Program responds with output, and a prompt:
  
  Lookahead set to 3.  I am X, you are O.
  Enter h for help
  X moves from 1 to 5, yielding .xxxx..oooo
  alak>
   ...and now you enter the commands to play.

=head1 DESCRIPTION

This module implements a simple game-tree system for the computer to
play against the user in a game of Alak.  You can just play the game
for fun; or you can use this module as a starting point for
understanding game trees (and implementing smarter strategy -- the
module's current logic is fairly simple-minded), particularly after
reading my I<Perl Journal> #18 article on trees, which discusses this
module's implementation of game trees as an example of general
tree-shaped data structures.

=head1 RULES

Alak was invented by the mathematician A. K.  Dewdney, and described
in his 1984 book I<Planiverse>. The rules of Alak are simple -- at
least as I've (mis?)understood them and implemented them here:

* Alak is a two-player game played on a one-dimensional board with
eleven slots on it.  Each slot can hold at most one piece at a time.
There's two kinds of pieces, which I represent here as "x" and "o" --
x's belong to one player (called X -- that's the computer), o's to the
other (called O -- that's you).

* The initial configuration of the board is:

   xxxx___oooo
   
For sake of reference, the slots are numbered from 1 (on the left) to
11 (on the right), and X always has the first move.

* The players take turns moving.  At each turn, each player can move
only one piece, once.  (This is unlike checkers, where you move one piece
per move but get to keep moving it if you jump an your opponent's
piece.) A player cannot pass up on his turn.  A player can move any one
of his pieces to the next unoccupied slot to its right or left, which
may involve jumping over occupied slots.  A player cannot move a piece
off the side of the board.

* If a move creates a pattern where the opponent's pieces are
surrounded, on both sides, by two pieces of the mover's color (with no
intervening unoccupied blank slot), then those surrounded pieces are
removed from the board.

* The goal of the game is to remove all of your opponent's pieces, at
which point the game ends.  Removing all-but-one ends the game as
well, since the opponent can't surround you with one piece, and so will
always lose within a few moves anyway.

=head1 SAMPLE GAME

A game between X (computer) and a particularly dim O (human):

  xxxx___oooo
    ^         Move 1: X moves from 3 (shown with caret) to 5
               (Note that any of X's pieces could move, but
               that the only place they could move to is 5.)
  xx_xx__oooo
          ^   Move 2: O moves from 9 to 7.
  xx_xx_oo_oo
     ^        Move 3: X moves from 4 to 6.
  xx__xxoo_oo
           ^  Move 4: O (stupidly) moves from 10 to 9.
  xx__xxooo_o
      ^       Move 5: X moves from 5 to 10, making the board
              "xx___xoooxo".  The three o's that X just
              surrounded are removed. 
  xx___x___xo
              O has only one piece, so has lost.

=head1 INTERFACE

This module uses C<Term::ReadLine> to give you a prompt at which you
can type commands.

Entering "h" for help at that prompt will give instructions on how
to interact with the game.

When in doubt, consult the source -- it's made to be fairly clear.

=head1 REFERENCES

Burke, Sean M.  2000.  "Trees".  (In submission: actual article title
may differ.)  Article in I<The Perl Journal> #18.  C<http://www.tpj.com/>
[Portions of this POD are excerpted from that article.]

Dewdney, A[lexander] K[eewatin].  1984.  I<Planiverse: Computer Contact
with a Two-Dimensional World.>  Poseidon Press, New York.

=head1 COPYRIGHT

Copyright (c) 2000-2006 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Current maintainer Avi Finkel, C<avi@finkel.org>; Original author Sean M. Burke, C<sburke@cpan.org>

Thanks to A. K. Dewdney (C<http://www.dewdney.com/>) for his
encouragement in writing my (abovementioned) TPJ article, as well as
for having written the enjoyable book where he briefly describes it.

=cut

