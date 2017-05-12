package KGS::Game::Board;

=head1 NAME

KGS::Game::Board - represents a go board

=head1 SYNOPSIS

   use KGS::Game::Board;

=head1 DESCRIPTION

Please supply a description )

=head2 METHODS

=over 4

=cut

use Gtk2::GoBoard::Constants;

use KGS::Constants;

=item my $board = new $size

Creates a new empty board of the given size.

C<< $board->{captures}[COLOUR] >> stores the number of captured stones for
the given colour.

C<< $board->{score}[COLOUR] >> stores the score (if available) for
the given colour, else C<undef>.

C<< $board->{timer}[COLOUR] >> stores the C<< [$time, $count] >> remaining time
info for the given user, if known. C<undef> otherwise.

C<< $board->{last} >> stores the colour of the last move that was played.

C<< $board->{board} >> stores a two-dimensional array with board contents.

=cut

sub new {
   my $class = shift;
   my $size = shift;
   bless {
         max      => $size - 1,
         board    => [map [(0) x $size], 1 .. $size],
         captures => [0, 0], # captures
        #timer    => [],
        #score    => [],
        #last     => COLOUR_...,
      },
      $class;
}

# inefficient and primitive, I hear you say?
# well... you are right :)
# use an extremely dumb floodfill algorithm to get rid of captured stones
sub capture {
   my ($self, $mark, $x, $y) = @_;

   my %seen;
   my @found;
   my @nodes = ([$x,$y]);
   my $board = $self->{board};

   my $max = $self->{max};

   while (@nodes) {
      my ($x, $y) = @{pop @nodes};
      unless ($seen{$x,$y}++) {
         if ($board->[$x][$y] & $mark) {
            push @found, [$x, $y];

            push @nodes, [$x-1, $y] unless $seen{$x-1, $y} || $x <= 0;
            push @nodes, [$x+1, $y] unless $seen{$x+1, $y} || $x >= $max;
            push @nodes, [$x, $y-1] unless $seen{$x, $y-1} || $y <= 0;
            push @nodes, [$x, $y+1] unless $seen{$x, $y+1} || $y >= $max;
         } elsif (!($board->[$x][$y] & (MARK_B | MARK_W))) {
            return;
         }
      }
   }

   @found;
}

=item $board->interpret_path ($path)

Interprets the path (as returned by C<KGS::Game::Tree::get_path>) and leaves
the board in the state that it reaches after executing all the pth nodes.

=cut

sub interpret_path {
   my ($self, $path) = @_;

   my $board = $self->{board};

   my $move;

   $self->{last}    = COLOUR_WHITE; # black always starts.. ehrm..
   $self->{curnode} = $path->[-1];

   for (@$path) {
      # mask out all labeling except in the last node
      my $nodemask =
            $_ == $path->[-1]
               ? ~0
               : ~(MARK_SQUARE | MARK_TRIANGLE | MARK_CIRCLE | MARK_LABEL | MARK_KO);

      while (my ($k, $v) = each %$_) {
         if ($k =~ /^(\d+),(\d+)$/) {
            my $v0 = $v->[0];

            $board->[$1][$2] =
               $board->[$1][$2]
               & ~$v->[1]
               | $v0
               & $nodemask;

            $self->{label}[$1][$2] = $v->[2] if $v0 & MARK_LABEL;

            if ($v0 & MARK_MOVE) {
               $self->{last} = $v0 & MARK_B ? COLOUR_BLACK : COLOUR_WHITE;

               unless ($v->[3]) {
                  my ($x, $y) = ($1, $2);

                  my ($own, $opp) =
                     $v0 & MARK_B
                        ? (MARK_B, MARK_W)
                        : (MARK_W, MARK_B);

                  my (@capture, $suicide);

                  push @capture, $self->capture ($opp, $x-1, $y) if $x > 0            && $board->[$x-1][$y] & $opp;
                  push @capture, $self->capture ($opp, $x+1, $y) if $x < $self->{max} && $board->[$x+1][$y] & $opp;
                  push @capture, $self->capture ($opp, $x, $y-1) if $y > 0            && $board->[$x][$y-1] & $opp;
                  push @capture, $self->capture ($opp, $x, $y+1) if $y < $self->{max} && $board->[$x][$y+1] & $opp;

                  # remove captured stones
                  $self->{captures}[$self->{last}] += @capture;
                  $self->{board}[$_->[0]][$_->[1]] &= ~(MARK_B | MARK_W | MARK_MOVE)
                     for @capture;

                  $suicide += $self->capture ($own, $x, $y  );

                  $v->[3] ||= !(@capture || $suicide);

                  if (!$suicide && @capture == 1) {
                     # possible ko. now check liberties on placed stone

                     my $libs;

                     $libs++ if $x > 0            && !($board->[$x-1][$y] & $opp);
                     $libs++ if $x < $self->{max} && !($board->[$x+1][$y] & $opp);
                     $libs++ if $y > 0            && !($board->[$x][$y-1] & $opp);
                     $libs++ if $y < $self->{max} && !($board->[$x][$y+1] & $opp);
                     
                     if ($libs == 1) {
                        $board->[$x][$y] = $board->[$x][$y] & ~MARK_CIRCLE | (MARK_KO & $nodemask);
                        ($x, $y) = @{$capture[0]};
                        $board->[$x][$y] |= MARK_KO & $nodemask;
                     }
                  }
               }
            }

         } elsif ($k eq "timer") {
            $self->{timer}[0] = $v->[0] if defined $v->[0];
            $self->{timer}[1] = $v->[1] if defined $v->[1];

         } elsif ($k eq "pass") {
            $self->{last} = 1 - $self->{last};

         } elsif ($k eq "score") {
            $self->{score} = $v;
         }
      }

      $move++;
   }
}

=item $board->is_valid_move ($colour, $x, $y[, $may_suicide])

Returns true if the move of the given colour on the given coordinates is
valid or not.

=cut

sub is_valid_move {
   my ($self, $colour, $x, $y, $may_suicide) = @_;

   my $board = $self->{board};

   return if $board->[$x][$y] & (MARK_B | MARK_W | MARK_KO);

   if ($may_suicide) {
      return 1;
   } else {
      my ($own, $opp) = $colour == COLOUR_BLACK
                           ? (MARK_B, MARK_W)
                           : (MARK_W, MARK_B);

      # try the move
      local $board->[$x][$y] = $board->[$x][$y] | $own;

      return 1 if $x > 0            && $board->[$x-1][$y] & $opp && $self->capture ($opp, $x-1, $y, 1);
      return 1 if $x < $self->{max} && $board->[$x+1][$y] & $opp && $self->capture ($opp, $x+1, $y, 1);
      return 1 if $y > 0            && $board->[$x][$y-1] & $opp && $self->capture ($opp, $x, $y-1, 1);
      return 1 if $y < $self->{max} && $board->[$x][$y+1] & $opp && $self->capture ($opp, $x, $y+1, 1);

      return !$self->capture ($own, $x, $y, 1);
   }
}

1;

=back

=head2 AUTHOR

Marc Lehmann <pcg@goof.com>

=head2 SEE ALSO

L<KGS::Protocol>, L<KGS::Game::Tree>, L<Gtk2::GoBoard>.

=cut

