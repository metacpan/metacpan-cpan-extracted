package Games::Go::SimpleBoard;

=head1 NAME

Games::Go::SimpleBoard - represent a simple go board

=head1 SYNOPSIS

   use Games::Go::SimpleBoard;

=head1 DESCRIPTION

Please supply a description )

=head2 EXPORTED CONSTANTS

Marker types for each board position (ORed together):

   MARK_B            # normal black stone
   MARK_W            # normal whit stone
   MARK_GRAYED       # in conjunction with MARK_[BW], grays the stone

   MARK_SMALL_B      # small stone, used for scoring or marking
   MARK_SMALL_W      # small stone, used for scoring or marking
   MARK_SMALL_GRAYED # in conjunction with MARK_SMALL_[BW], grays the stone

   MARK_TRIANGLE     # triangle mark
   MARK_SQUARE       # square mark
   MARK_CIRCLE       # circle mark
   MARK_CROSS        # cross mark

   MARK_LABEL        # a text label
   MARK_HOSHI        # this is a hoshi point (not used much)
   MARK_MOVE         # this is a regular move
   MARK_KO           # this is a ko position
   MARK_REDRAW       # ignored, can be used for your own purposes

   COLOUR_WHITE      # guaranteed to be 0
   COLOUR_BLACK      # guaranteed to be 1

   MOVE_HANDICAP     # used as "x-coordinate" for handicap moves
   MOVE_PASS         # can be used as "x-coordinate" for pass moves

=head2 METHODS

=over 4

=cut

no warnings;
use strict;

use Carp ();

use base Exporter::;

our $VERSION = '1.01';

our @EXPORT = qw(
   MARK_TRIANGLE MARK_SQUARE MARK_CIRCLE MARK_SMALL_B MARK_SMALL_W MARK_B
   MARK_W MARK_GRAYED MARK_SMALL_GRAYED MARK_MOVE MARK_LABEL MARK_HOSHI MARK_KO MARK_CROSS
   MARK_REDRAW
   COLOUR_BLACK COLOUR_WHITE
   MOVE_HANDICAP MOVE_PASS
);

# marker types for each board position (ORed together)

sub MARK_TRIANGLE     (){ 0x0001 }
sub MARK_SQUARE       (){ 0x0002 }
sub MARK_CIRCLE       (){ 0x0004 }
sub MARK_CROSS        (){ 0x0008 }

sub MARK_SMALL_B      (){ 0x0010 } # small stone, used for scoring or marking
sub MARK_SMALL_W      (){ 0x0020 } # small stone, used for scoring or marking
sub MARK_SMALL_GRAYED (){ 0x0040 }

sub MARK_B            (){ 0x0080 } # normal black stone
sub MARK_W            (){ 0x0100 } # normal whit stone
sub MARK_GRAYED       (){ 0x0200 } # in conjunction with MARK_[BW], grays the stone

sub MARK_LABEL        (){ 0x0400 }
sub MARK_HOSHI        (){ 0x0800 } # this is a hoshi point (not used much)
sub MARK_MOVE         (){ 0x1000 } # this is a regular move
sub MARK_KO           (){ 0x2000 } # this is a ko position
sub MARK_REDRAW       (){ 0x8000 }

sub COLOUR_WHITE      (){ 0 }
sub COLOUR_BLACK      (){ 1 }

sub MOVE_PASS         (){ undef }
sub MOVE_HANDICAP     (){ -2 }

=item my $board = new $size

Creates a new empty board of the given size.

C<< $board->{size} >> stores the board size.

C<< $board->{max} >> stores the maximum board coordinate (size-1).

C<< $board->{captures}[COLOUR_xxx] >> stores the number of captured stones for
the given colour.

C<< $board->{board} >> stores a two-dimensional array with board contents.

=cut

sub new {
   my $class = shift;
   my $size = shift;

   unless ($size > 0) {
      Carp::croak ("no board size given!");
   }

   bless {
      max       => $size - 1,
      size      => $size,
      board     => [map [(0) x $size], 1 .. $size],
      captures  => [0, 0], # captures
     #timer     => [],
     #score     => [],
      @_,
   }, $class
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

   @found
}

=item $hint = $board->update ([update-structures...])

Each update-structure itself is also an array-ref:

   [$x, $y, $clr, $set, $label, $hint] # update or move
   [MOVE_HANDICAP, $handicap]          # black move, setup handicap
   [MOVE_PASS]                         # pass
   []                                  # also pass (deprecated!)

It changes the board or executes a move, by first clearing the bits
specified in C<$clr>, then setting bits specified in C<$set>.

If C<$set> includes C<MARK_LABEL>, the label text must be given in
C<$label>.

If C<$set> contains C<MARK_MOVE> then surrounded stones will be removed
from the board and (simple) Kos are detected and marked with square
symbols and C<MARK_KO>, after removing other marking symbols. The
markings are also removed with the next next update structure that uses
C<MARK_MOVE>, so this flag is suited well for marking, well, moves. Note
that you can make invalid "moves" (such as suicide) and C<update> will
try to cope with it. You can use C<is_valid_move> to avoid making illegal
moves.

For handicap "moves", currently only board sizes 9, 13 and 19 are
supported and only handicap values from 2 to 9. The placement follows the
IGS rules, if you want other placements, you have to set it up yourself.

This function modifies the C<$hint> member of the specified structure
to speed up repeated board generation and updates with the same update
structures.

If the hint member is a reference the scalar pointed to by the reference
is updated instead.

If all this hint member thing is confusing, just ignore it and specify
it as C<undef> or leave it out of the array entirely. Do make sure that
you keep your update structures around as long as previous updates don't
change, however, as regenerating a full board position from hinted
update structures is I<much> faster then recreating it from fresh update
structures.

Example, make two silly moves:

  $board->update ([[0, 18, -1, MARK_B | MARK_MOVE],
                   [0, 17, -1, MARK_W | MARK_MOVE]]);

=cut

our %HANDICAP_COORD =  (
    9 => [2, 4,  6],
   13 => [3, 6,  9],
   19 => [3, 9, 15],
);
our %HANDICAP_XY = (
   2 => [qw(0,2 2,0                            )],
   3 => [qw(0,2 2,0 0,0                        )],
   4 => [qw(0,2 2,0 0,0 2,2                    )],
   5 => [qw(0,2 2,0 0,0 2,2                 1,1)],
   6 => [qw(0,2 2,0 0,0 2,2 0,1 2,1            )],
   7 => [qw(0,2 2,0 0,0 2,2 0,1 2,1         1,1)],
   8 => [qw(0,2 2,0 0,0 2,2 0,1 2,1 1,0 1,2    )],
   9 => [qw(0,2 2,0 0,0 2,2 0,1 2,1 1,0 1,2 1,1)],
);

our $mark_symbols = MARK_CIRCLE | MARK_SQUARE | MARK_TRIANGLE | MARK_CROSS | MARK_KO;

sub update {
   my ($self, $path) = @_;

   my $board = $self->{board};

   for (@$path) {
      my ($x, $y, $clr, $set, $label) = @$_;

      if (!defined $x) {
         $$_ &= ~$mark_symbols for @{ delete $self->{unmark} || [] };
         # pass

      } elsif ($x == MOVE_HANDICAP) {
         $$_ &= ~$mark_symbols for @{ delete $self->{unmark} || [] };

         # $y = #handicap stones
         my $c = $HANDICAP_COORD{$self->{size}}
            or Carp::croak "$self->{size}: illegal board size for handicap";
         my $h = $HANDICAP_XY{$y}
            or Carp::croak "$y: illegal number of handicap stones";

         for (@$h) {
            my ($x, $y) = map $c->[$_], split /,/;
            $board->[$x][$y] = MARK_B | MARK_MOVE;
         }

      } else {
         my $space = \$board->[$x][$y];

         $$space = $$space & ~$clr | $set;

         $self->{label}[$x][$y] = $label if $set & MARK_LABEL;

         if ($set & MARK_MOVE) {
            $$_ &= ~$mark_symbols for @{ $self->{unmark} || [] };
            @{ $self->{unmark} } = $space;

            # remark the space, in case the move was on the same spot as the
            # old mark
            $$space |= $set;

            unless (${ $_->[5] ||= \my $hint }) {
               my ($own, $opp) =
                  $set & MARK_B
                     ? (MARK_B, MARK_W)
                     : (MARK_W, MARK_B);

               my (@capture, @suicide);

               push @capture, $self->capture ($opp, $x-1, $y) if $x > 0            && $board->[$x-1][$y] & $opp;
               push @capture, $self->capture ($opp, $x+1, $y) if $x < $self->{max} && $board->[$x+1][$y] & $opp;
               push @capture, $self->capture ($opp, $x, $y-1) if $y > 0            && $board->[$x][$y-1] & $opp;
               push @capture, $self->capture ($opp, $x, $y+1) if $y < $self->{max} && $board->[$x][$y+1] & $opp;

               # keep only unique coordinates
               @capture = do { my %seen; grep !$seen{"$_->[0],$_->[1]"}++, @capture };

               # remove captured stones
               $self->{captures}[$own == MARK_B ? COLOUR_BLACK : COLOUR_WHITE] += @capture;
               $self->{board}[$_->[0]][$_->[1]] = 0
                  for @capture;

               push @suicide, $self->capture ($own, $x, $y);

               ${ $_->[5] } ||= !(@capture || @suicide);

               if (@suicide) {
                  $self->{board}[$_->[0]][$_->[1]] = 0
                     for @suicide;
                  # count suicides as other sides stones
                  $self->{captures}[$opp == MARK_B ? COLOUR_BLACK : COLOUR_WHITE] += @suicide;
                  
               } elsif (!@suicide && @capture == 1) {
                  # possible ko. now check liberties on placed stone

                  my $libs;

                  $libs++ if $x > 0            && !($board->[$x-1][$y] & $opp);
                  $libs++ if $x < $self->{max} && !($board->[$x+1][$y] & $opp);
                  $libs++ if $y > 0            && !($board->[$x][$y-1] & $opp);
                  $libs++ if $y < $self->{max} && !($board->[$x][$y+1] & $opp);
                  
                  if ($libs == 1) {
                     $$space = $$space & ~$mark_symbols | MARK_KO;

                     ($x, $y) = @{$capture[0]};
                     $board->[$x][$y] |= MARK_KO;

                     push @{ $self->{unmark} }, \$board->[$x][$y];
                  }
               }
            }
         }
      }
   }
}

=item $board->is_valid_move ($colour, $x, $y[, $may_suicide])

Returns true if the move of the given colour on the given coordinates is
valid or not. Kos are taken into account as long as they are marked with
C<MARK_KO>. Suicides are invalid unless C<$may_suicide> is true (e.g. for
new zealand rules)

=cut

sub is_valid_move {
   my ($self, $colour, $x, $y, $may_suicide) = @_;

   my $board = $self->{board};

   return if $board->[$x][$y] & (MARK_B | MARK_W | MARK_KO)
             && !($board->[$x][$y] & MARK_GRAYED);

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

Marc Lehmann <schmorp@schmorp.de>

=head2 SEE ALSO

L<Gtk2::GoBoard>.

=cut

