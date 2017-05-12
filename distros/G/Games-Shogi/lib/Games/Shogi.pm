package Games::Shogi;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.03';

sub size() { 9 }
sub promotion_zone() { 3 }
sub allow_drop() { 1 }
sub capture() { ['K'] }

# {{{ Board static data
my @board = (
    #    9 8 7 6 5 4 3 2 1
    [qw( L N S G K G S N L )],   # a
    [qw( _ R _ _ _ _ _ B _ )],   # b
    [qw( P P P P P P P P P )],   # c
    [qw( _ _ _ _ _ _ _ _ _ )],   # d
    [qw( _ _ _ _ _ _ _ _ _ )],   # e
    [qw( _ _ _ _ _ _ _ _ _ )],   # f
    [qw( p p p p p p p p p )],   # g
    [qw( _ b _ _ _ _ _ r _ )],   # h
    [qw( l n s g k g s n l )] ); # i
# }}}

# {{{ Pieces
my $pieces = {
  # {{{ Bishop
  b => {
    name => 'Bishop',
    romaji => 'kakugyo',
    promote => 'dh',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Gold General
  g => {
    name => 'Gold General',
    romaji => 'kinsho',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ King
  k => {
    name => 'King',
    romaji => 'osho',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Knight
  n => {
    name => 'Knight',
    romaji => 'keima',
    promote => 'g',
    neighborhood => [
      q( x x ),
      q(     ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Lance
  l => {
    name => 'Lance',
    romaji => 'kyosha',
    promote => 'g',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Pawn
  p => {
    name => 'Pawn',
    romaji => 'fuhyo',
    promote => '+p',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Rook
  r => {
    name => 'Rook',
    romaji => 'hisha',
    promote => 'dk',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Silver General
  s => {
    name => 'Silver General',
    romaji => 'ginsho',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}

  # {{{ Dragon Horse
  dh => {
    name => 'Dragon Horse',
    romaji => 'ryume',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q( o^o ),
      q( /o\ ),
      q(     ) ] },
  # }}}
  # {{{ Dragon King
  dk => {
    name => 'Dragon King',
    romaji => 'ryuo',
    neighborhood => [
      q(     ),
      q( o|o ),
      q( -^- ),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Promoted Pawn
  '+p' => {
    name => 'Promoted Pawn',
    romaji => 'tokin',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
};
# }}}

# {{{ new
sub new {
  my $proto = shift;
  my $self = { pieces => $pieces };
  bless $self, ref($proto) || $proto;
  $self->{board} = $self->initial_board(\@board);
  return $self }
# }}}

# {{{ initial_board
sub initial_board {
  my ($self,$board) = @_;

  return [ map { [ map { $_ eq '_' ? undef : $_ } @$_ ] } @$board ] }
# }}}

# {{{ neighbor
sub neighbor {
  my ($self,$piece) = @_;
  return unless $self->{pieces}->{lc $piece};

  my $reverse = {
    U => 'D', D => 'U', R => 'L', L => 'R',
    u => 'd', d => 'u', r => 'l', l => 'r',
  };
  my @dir_map = (
    [qw( uuulll  uuull uuul uuu uuur uuurr uuurrr)],
    [qw(  uulll   uull  uul  uu uur  uurr  uurrr )],
    [qw(   ulll    ull   ul  u  ur   urr   urrr  )],
    [qw(    lll     ll    l  _  r    rr    rrr   )],
    [qw(   dlll    dll   dl  d  dr   drr   drrr  )],
    [qw(  ddlll   ddll  ddl dd  ddr  ddrr  ddrrr )],
    [qw( dddlll  dddll dddl ddd dddr dddrr dddrrr)] );
  my $dir_center = int(@dir_map/2);

  my $desc = $self->{pieces}->{lc $piece}{neighborhood};
  my @foo = map { [ split // ] } @$desc;
  my $center = int(@$desc/2);
  my $neighbors = [];

  for my $dx (-$center..+$center) {
    for my $dy (-$center..+$center) {
      next if $dx == 0 and $dy == 0; # Center
      my $move = $foo[$center+$dx][$center+$dy];
      if($move =~ /\d/) {
        my $td = $dir_map[$dir_center+$dx][$dir_center+$dy];
        if($td=~/(\w)(\w)/) {
          push @$neighbors,$1 x $move.$2 x $move }
        else {
          push @$neighbors,$td x $move } }
      elsif($move =~ /[xo]/) {
        push @$neighbors,$dir_map[$dir_center+$dx][$dir_center+$dy] }
      elsif($move =~ m{[-|\\/]} and abs($dx) < 2 and abs($dy) < 2) {
        push @$neighbors,uc $dir_map[$dir_center+$dx][$dir_center+$dy] }
      elsif($move =~ m{[-|\\/]}) { $neighbors->[-1] .= '*' } } }
use YAML;die Dump($neighbors) if lc $piece eq 'do';

 return [ map { s/([udlrUDLR])/$reverse->{$1}/g; $_ } @$neighbors ]
   if uc $piece eq $piece;
 return $neighbors }
# }}}

sub board { return shift->{board} }
sub english_name { return shift->{pieces}{lc shift()}{name} }
sub japanese_name { return shift->{pieces}{lc shift()}{romaji} }
sub promote { return shift->{pieces}{lc shift()}{promote} }

1;
__END__

=head1 NAME

Games::Shogi - Base class describing the Shogi game and variants

=head1 SYNOPSIS

  use Games::Shogi;
  $Game = Games::Shogi->new;
  $tl_piece = $Game->board()->[0][0];
  print @{$Game->neighbor($tl_piece)};
  print $Game->japanese_name('g'); # kinsho

=head1 DESCRIPTION

=over

=item initial_board()

Return a 2-D array of piece abbreviations in the initial board configuration.

=item neighbor($piece_abbr)

Return an array of directions that a given piece can travel. See below for descriptions of other restrictions that exist in the game, and the example source for how to use the directions in the course of an actual game.

=item board()

Return the board contents as a 2-D array reference.

=item english_name($piece_abbr)

Return the English name for the given piece.

=item japanese_name($piece_abbr)

Return the Japanese name in romaji for the given piece.

=item promote($piece_abbr)

Return what the piece promotes to, or undef if no promotion exists.

=back

=head2 RULES SUMMARY

Much like Western chess, shogi is a two-player game on a square board. The most commonly-played variety is played on a 9-by-9 board, but subclasses implement games from Micro Shogi's 4 x 5 board to Taikyoku Shogi's 36 x 36 board, with more than 400 types of pieces.

In ASCII graphics, the initial layout looks like this:

   9 8 7 6 5 4 3 2 1
  +-----------------+
  |L N S G K G S N L|a
  |  R           B  |b
  |P P P P P P P P P|c
  |                 |d
  |                 |e
  |                 |f
  |p p p p p p p p p|g
  |  b           r  |h
  |l n s g k g s n l|i
  +-----------------+

The ranks read top to bottom, as in Western chess, but the files read right-to-left, following Japanese convention. Unlike Western chess, pawns have no special powers (I.E. they capture and move one square in front of them, no en passant captures, no two-square first move). Knights move like in Western chess, but only to the two squares in front of them. The rook and bishop move as in Western chess, but when they promote they gain the ability to move one square in any direction.

Pieces can promote by moving into or within the opponent's third rank. This is not mandatory, except for pieces that otherwise would be unable to move, such as a pawn or lance on the last rank, and knights in the last two ranks.

If a player captures an opponent's piece, it is B<not> taken out of the game. Instead, it is said to be 'in hand.' The piece has any promotions taken away, but to compensate the player may elect to drop any piece they have in hand back onto the board instead of moving a piece on the board, subject to the following restrictions:

=over 2

=item * Only one unpromoted pawn per file

=item * A pawn may not be dropped to give direct checkmate

=item * Pieces may not be dropped where they have no legal move

=item * A piece may not be promoted as it is dropped

=back

Of course, checkmating the king is the object of the game. The king can escape check by moving out of check, interposing or dropping a piece to block the checking piece, or capturing the piece giving check.

=head2 PIECE DESCRIPTIONS

Since this module is basically an encapsulation of Shogi pieces for use in board games, the internal C<$piece> hashref encodes a great deal of information about the pieces.

Pieces are indexed by a chosen (up to 4 letter) lower-case abbreviation that corresponds to what you see in the board description. Collisions are all too frequent, and in general the piece in the more common game wins. Following the pattern set up by the Gold and Silver generals, other generals such as the Tile General and Wood General also get their one-letter abbreviations when they don't collide with established abbreviations.

Some Shogi pieces do promote, and those are given a 'promote' key corresponding to the index of the piece they promote to. In some games it's possible for a piece to promote more than once, in which case it simply promotes to the next piece.

For some, not all, pieces the English pronunciation of their Japanese name is given, and eventually the Unicode equivalents will be added, if they actually exist.

Of course, this information would be useless if we didn't describe how the pieces move and capture. Where possible, we represent a piece's neighborhood of where it can move to on a 5x5 grid, which looks roughly like this internally:

  cm => {
    name => 'Center Master',
    neighborhood => [
      q(x x x),
      q( \|/ ),
      q(o3^3o),
      q( 3|3 ),
      q(o x o) ] },

I'm not sure of the piece's Japanese pronunciation, and to the best of my knowledge it doesn't promote, so those keys simply don't exist. The neighborhood is where this piece can move to, and is fairly complex. There are worse pieces, but those generally have to be dealt with on a case-by-case basis. We'll cover some of those later.

Working from the center of the diagram out, the '\', '|' and '/' represent directions in which the piece can slide until it reaches another piece. '/' represents the ability to slide to the northeast along a diagonal, '\' to the northwest, and so on.

The piece can also jump over intervening friendly pieces, and that ability is captured by the 'x' among the top row. This simply says that the Center Master can jump two squares to the north, northeast and northwest. Furthermore, the 'o3' and '3o' notations mean that the piece can slide 3 squares east, west, southeast and southwest.

Another special class of piece is the Hook Mover.

  pc => {
    name => 'Peacock',
    promote => 'lng',
    neighborhood => [
      q(X   X),
      q( \ / ),
      q(  ^  ),
      q( o o ),
      q(o   o) ] },

The 'X' here represents a Hook Mover piece as opposed to a jumping piece. The Peacock is a diagonal hook mover, other pieces (with the hook represented by '+' move orthogonally. The Peacock can slide any distance on the forward diagonals, turn 90 degrees, and keep moving.

Orthogonal hook movers (those with '+' at the end of a '|' or '-') slide any distance on the orthogonal, then turn 90 degrees and keep moving.

Of course, some pieces can jump where others merely slide. Take, for an extreme example, the Great General in Tenjiku Shogi and larger:

  \ | /
   \|/
  --^--
   /|\
  / | \

The doubled dashes, diagonals &c indicate that this piece can jump over any intervening pieces in any direction. Unlike the Fire Demon, however, the Great General can only capture the piece it lands on.

Pieces below are pretty much too complex to code reasonably, and have to have special exceptions made in the move logic.

=over Miscellaneous Pieces

=item Lion

  22222
  21112
  21^12
  21112
  22222

Lions can slide to any square marked 1, or jump to a square marked 2. It can also slide to any square marked 1, then slide back to its starting square, effectively passing.

When capturing, Lions use what's known as an igui power. This is to say that they can capture on any square numbered 1, and either capture another piece on an adjacent square marked 1 or capture on an adjacent square marked 2.

If you capture your opponent's Lion with a Lion, you can only do so if your opponent's Lion is either undefended and on a square marked 2, or if you use your igui power to capture a piece that is not a Pawn or Go-Between on a square marked 1.

Otherwise, capturing your opponent's Lion with a piece that is not a Lion is subject to the restriction that your opponent can't capture your Lion on her turn unless it's with another Lion.

=item Horned Falcon

    2
   \1/
   -^-
   /|\

The Horned Falcon can capture a piece on the square marked 1 and then either return to its starting square or capture a piece on the square marked 2, using its igui power.

=item Soaring Eagle

  2   2
   1|1
   -^-
   /|\

The Soaring Eagle also has igui power.

=item Fire Demon

  \   |   /
   ooooooo
   ooooooo
   oo!!!oo
  -oo!^!oo-
   oo!!!oo
   ooooooo
   ooooooo
  /   |   \

Tenjiku Shogi introduces the Fire Demon, with yet another complicated move. This piece can slide to any piece within three squares and capture there. It can also slide like the Western queen, with the added benefit that when it stops, it captures any enemy pieces on the squares marked '!'.

=item Vice General

  \   |   /
   ooooooo
   ooooooo
   ooooooo
  -ooo^ooo-
   ooooooo
   ooooooo
   ooooooo
  /   |   \

The Vice General is nearly the equivalent of the Fire Demon, except that it can't burn pieces one square away like the Fire Demon can.

=item Lion Hawk

  \  |  /
   22222
   21112
  -21^12-
   21112
   22222
  /  |  \

The Lion Hawk is essentially the Lion with the ability to range. Thankfully it can't use both the ranging and the igui power in the same move.

=item Heavenly Tetrarchs

   \   /
    !!!
  ox!^!xo
    !!!
   /   \

Like the Fire Demon, it can burn any piece in a one-square radius when it stops sliding. Unlike the Fire Demon, it can't move to any square just one away. It either has to follow the diagonals or jump to the 'x' or 'o' squares.

=item Buddhist Spirit

This moves as a Lion Hawk, essentially.

=item Furious Fiend

This moves as either the Lion Hawk or Lion Dog.

=item Emperor

The Emperor can move to any open square on the board, and capture any piece that isn't being defended by another piece. It has to be captured to win the game, so it seems that the only way to win is capture any pieces defending the emperor, then go in for the kill.

=back

=head2 OTHER VARIANTS

Many other variants of Shogi exist and are still played today. The subclasses C<Games::Shogi::Tenjiku>, C<Games::Shogi::Taikyoku> etc. describe variants of Shogi that have a wide variety of pieces and powers. Pieces with special powers are detailed in the individual subclasses, but a few pieces deserve special notice.

For instance, the Fire Demon (in Tenjiku Shogi, among others) can move three squares in any direction, slide diagonally, *and* captures ("burns") any enemy piece in a one-square radius. The Lion (also in Tenjiku Shogi) can move one square any direction, capture, and choose to move one more square in any direction.

=head2 EXPORT

None

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
