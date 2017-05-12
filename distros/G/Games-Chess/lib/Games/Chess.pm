#------------------------------------------------------------------------------
# Games::Chess - represent chess pieces, positions, moves and games
#
# AUTHOR
#   Gareth Rees <garethr@cre.canon.co.uk>
# 
# COPYRIGHT
#   Copyright (c) 1999 Gareth Rees.  This module is free software: you 
#   can distribute and/or modify it under the same terms as Perl itself.
#
# $Id: Chess.pm,v 1.5 1999/06/06 18:47:24 gareth Exp $
#------------------------------------------------------------------------------

package Games::Chess;
use base 'Exporter';
use strict;
use vars qw($RCSID $VERSION $ERRMSG $DEBUG @EXPORT @EXPORT_OK %EXPORT_TAGS);

$RCSID = q$Id: Chess.pm,v 1.5 1999/06/06 18:47:24 gareth Exp $;
$VERSION = '0.003';
$ERRMSG = '';
$DEBUG = 0;
@EXPORT = ();
@EXPORT_OK = qw(algebraic_to_xy colour_valid debug errmsg error
                halfmove_count_valid move_number_valid piece_valid xy_valid
                xy_to_algebraic
                EMPTY WHITE BLACK PAWN KNIGHT BISHOP ROOK QUEEN KING);
%EXPORT_TAGS =
  ( colours   => [qw(EMPTY WHITE BLACK)],
    pieces    => [qw(EMPTY PAWN KNIGHT BISHOP ROOK QUEEN KING)],
    constants => [qw(EMPTY WHITE BLACK PAWN KNIGHT BISHOP ROOK QUEEN KING)],
    functions => [qw(algebraic_to_xy colour_valid debug errmsg
                     halfmove_count_valid move_number_valid piece_valid
                     xy_valid xy_to_algebraic)],
  );

use constant EMPTY => 0;
use constant WHITE => 1;
use constant BLACK => 2;

use constant PAWN   => 1;
use constant KNIGHT => 2;
use constant BISHOP => 3;
use constant ROOK   => 4;
use constant QUEEN  => 5;
use constant KING   => 6;

sub algebraic_to_xy ( $ ) {
  my ($sq) = @_;
  $sq =~ /^([a-h])([1-8])$/
    or return error("$sq does not specify a square in algebraic notation");
  return (ord($1) - ord('a'), $2 - 1);
}

sub colour_valid ( $ ) {
  my ($colour) = @_;
  return 1 if $colour == WHITE or $colour == BLACK;
  return error("colour $colour invalid: must be @{[WHITE]} or @{[BLACK]}");
}

sub debug ( $ ) {
  $DEBUG = shift;
}

sub errmsg () {
  return $ERRMSG;
}

sub error ( $ ) {
  $ERRMSG = shift;
  if ($DEBUG > 0) {
    my ($filename,$line) = (caller(2))[1,2];
    my $message = "$ERRMSG at $filename line $line\n";
    $DEBUG >= 2 ? die($message) : warn($message);
  }
  return;
}

sub halfmove_count_valid ( $ ) {
  my ($halfmove) = @_;
  return 1 if $halfmove =~ /^[0-9]+$/;
  return error("halfmove clock '$halfmove' not a non-negative integer");
}

sub move_number_valid ( $ ) {
  my ($move) = @_;
  return 1 if $move =~ /^[0-9]+$/ and $move > 0;
  return error("Fullmove number '$move' not a positive integer");
}

sub piece_valid ( $ ) {
  my ($piece) = @_;
  return 1 if PAWN <= $piece and $piece <= KING;
  return error("piece $piece invalid: not between @{[PAWN]} and @{[KING]}");
}

sub xy_to_algebraic ($$) {
  my ($x,$y) = @_;
  return unless xy_valid($x,$y);
  return chr($x + ord('a')) . ($y + 1);
}

sub xy_valid ($$) {
  my ($x,$y) = @_;
  return 1 if 0 <= $x and $x < 8 and 0 <= $y and $y < 8;
  return error("($x,$y) off chessboard: not in the range (0,0) to (7,7)");
}

#------------------------------------------------------------------------------
# Games::Chess::Piece - representation of a chess piece
# A piece is represented as a blessed reference to a byte.
#------------------------------------------------------------------------------

package Games::Chess::Piece;
use strict;
Games::Chess->import(qw(error piece_valid colour_valid));

my @COLOUR_NAMES = qw(empty white black unknown);
my @PIECE_NAMES = qw(square pawn knight bishop rook queen king unknown);
my $pieces = 'pnbrqk';
my @CODE_PIECE = split '', " $pieces ";
my $PIECE_CODES = " \U$pieces\E$pieces";
my %PIECE_CODES;
@PIECE_CODES{split '', $PIECE_CODES} = (0, 9..14, 17..22);

sub new {
  my ($class,$val) = @_;
  my $self = chr(0);
  if (@_ < 2) {
    # Use the default (empty square).
  } elsif (@_ > 3) {
    return error("Piece->new called with more than 3 arguments");
  } elsif (@_ == 3) {
    return unless colour_valid($_[1]);
    return unless piece_valid($_[2]);
    $self = chr(($_[1] << 3) + $_[2]);
  } elsif (UNIVERSAL::isa($val,'Games::Chess::Piece')) {
    $self = $$val;
  } elsif (exists $PIECE_CODES{$val}) {
    $self = chr($PIECE_CODES{$val});
  } elsif ($val !~ /^\d+$/) {
    return error("Piece->new('$val') invalid: '$val' not a chess piece");
  } elsif (0 <= $val and $val < 256 and $val == int $val) {
    $self = chr($val);
  } else {
    return error("Piece->new($val) invalid: $val outside range 0 to 255");
  }
  bless \$self, $class;
}

sub code ( $ ) {
  my ($self) = @_;
  my $col = (ord($$self) & 24) >> 3;
  my $code = $CODE_PIECE[ord($$self) & 7];
  return $col == 2 ? $code : uc($code);
}

sub colour ( $ ) {
  my ($self) = @_;
  return (ord($$self) & 24) >> 3;
}

sub colour_name ( $ ) {
  my ($self) = @_;
  return $COLOUR_NAMES[$self->colour];
}

sub name ( $ ) {
  my ($self) = @_;
  return join ' ', $self->colour_name, $self->piece_name;
}

sub piece ( $ ) {
  my ($self) = @_;
  return ord($$self) & 7;
}

sub piece_name ( $ ) {
  my ($self) = @_;
  return $PIECE_NAMES[$self->piece];
}

#------------------------------------------------------------------------------
# Games::Chess::Move - representation of a chess move
#------------------------------------------------------------------------------

package Games::Chess::Move;
use strict;
Games::Chess->import(qw(error xy_valid));

sub new {
  my ($class,$xs,$ys,$xd,$yd,@promotion) = @_;
  return unless xy_valid($xs,$ys) and xy_valid($xd,$yd);
  my $self = { from => [$xs,$ys], to => [$xd,$yd] };
  if (@promotion) {
    my $p = Games::Chess::Piece->new(@promotion);
    return unless $p;
    $self->{'promotion'} = $p;
  }
  return bless $self, $class;
}

sub cmp ( $$ ) {
  my ($a,$b) = @_;
  UNIVERSAL::isa($b, 'Games::Chess::Move') 
    or return error("Argument to 'cmp' must be of class Games::Chess::Move");
  return ($a->{'from'}[0] <=> $b->{'from'}[0]
	  or $a->{'from'}[1] <=> $b->{'from'}[1]
	  or $a->{'to'}[0] <=> $b->{'to'}[0]
	  or $a->{'to'}[1] <=> $b->{'to'}[1]
	  or do {
	    my $ap = $a->{'promotion'}; 
	    my $bp = $b->{'promotion'}; 
	    defined $ap ? (defined $bp ? $$ap <=> $$bp : -1) : 1
	  });
}

sub from ( $ ) {
  my ($self) = @_;
  return @{$self->{'from'}};
}

sub to ( $ ) {
  my ($self) = @_;
  return @{$self->{'to'}};
}

sub promotion ( $ ) {
  my ($self) = @_;
  return @{$self->{'promotion'}};
}

#------------------------------------------------------------------------------
# Games::Chess::Position - representation of a chess position
#------------------------------------------------------------------------------

package Games::Chess::Position;
use strict;
use vars '%gifs';
Games::Chess->import(qw(:constants :functions error));

my $init_pos = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

sub new {
  my ($class,$val) = @_;
  
  # Passed another Position object?  Return a copy.
  if (defined $val and UNIVERSAL::isa($val,'Games::Chess::Position')) {
    return bless { %$val }, $class;
  }
  
  # We've been passed a board position in Forsythe-Edwards Notation (FEN).
  my $self = { };
  $val = $init_pos unless $val;
  
  # Split the FEN string into fields.
  my @fields = split ' ', $val;
  
  # First element is board description: split into into ranks.
  my @ranks = split '/', $fields[0];
  @ranks == 8 or
    return error("Position '$fields[0]' does not have 8 ranks");
  
  # Turn each rank into an array of 8 piece codes.
  foreach my $r (0 .. 7) {
    my $rank = $ranks[$r];
    $rank =~ s/(\d)/' ' x $1/eg;
    length $rank == 8
      or return error("Rank $r '$rank' does not have 8 squares");
    $ranks[$r] = [ map { $PIECE_CODES{$_} } split '', $rank ];
    @{$ranks[$r]} == 8
      or return error("Rank $r '$rank' contains an invalid piece code");
  }
  
  # Transform the 2-d array and assemble into the board.
  $self->{'board'} = pack('C64', map { $ranks[7-$_%8][int($_/8)] } 0 .. 63);
  
  # Active color (defaults to white).
  $fields[1] = 'w' unless defined $fields[1];
  if ($fields[1] eq 'w') {
    $self->{'player_to_move'} = &WHITE;
  } elsif ($fields[1] eq 'b') {
    $self->{'player_to_move'} = &BLACK;
  } else {
    return error("Invalid player to move: '$fields[1]'");
  }
  
  # Castling availability (defaults to none).
  $fields[2] = '-' unless defined $fields[2];
  unless ($fields[2] eq '-') {
    (join '', sort split '', $fields[2]) eq $fields[2]
      or return error("Castling availability '$fields[2]' not sorted");
    foreach (split '', $fields[2]) {
      /^[KQkq]$/ or return error("Castling availability '$_' not KQkq");
      $self->{'can_castle'}{$_} = 1;
    }
  }

  # En passant target square (default none).
  $fields[3] = '-' unless defined $fields[3];
  unless ($fields[3] eq '-') {
    my @square = algebraic_to_xy($fields[3]);
    return unless @square == 2;
    $self->{'en_passant'} = [@square];
  }
  
  # Half-move clock (default 0).
  $fields[4] = '0' unless defined $fields[4];
  return unless halfmove_count_valid($fields[4]);
  $self->{'halfmove'} = $fields[4];
  
  # Fullmove number (default 1).
  $fields[5] = '1' unless defined $fields[5];
  return unless move_number_valid($fields[5]);
  $self->{'move'} = $fields[5];

  # All done.
  return bless $self, $class;
}

sub at {
  my ($self,$x,$y,@piece) = @_;
  return unless xy_valid($x,$y);
  return Games::Chess::Piece->new(vec($self->{'board'}, 8 * $x + $y, 8))
    unless @piece;
  my $p = Games::Chess::Piece->new(@piece);
  return unless defined $p;
  vec($self->{'board'}, 8 * $x + $y, 8) = ord $$p;
  return 1;
}

sub board ( $ ) {
  my ($self) = @_;
  return $self->{'board'};
}

sub can_castle {
  my ($self,$colour,$piece,$can_castle) = @_;
  my $p = Games::Chess::Piece->new($colour,$piece);
  return unless defined $p;
  my $code = $p->code;
  $code =~ /^[KQkq]$/ or return
    error("can_castle($colour,$piece) invalid: must be king or queen");
  return defined $self->{'can_castle'}{$code} unless defined $can_castle;
  if ($can_castle) {
    $self->{'can_castle'}{$code} = 1;
  } else {
    delete $self->{'can_castle'}{$code};
  }
  return 1;
}

sub clear ( $$$ ) {
  my ($self,$x,$y) = @_;
  return unless xy_valid($x,$y);
  vec($self->{'board'}, 8 * $x + $y, 8) = 0;
  return 1;
}

sub en_passant {
  my ($self,@en_passant) = @_;
  my $ep = $self->{'en_passant'};
  return defined $ep ? @$ep : () unless @en_passant;
  return unless xy_valid(@en_passant);
  $self->{'en_passant'} = [@en_passant];
  return 1;
}

sub halfmove_clock {
  my ($self,$halfmove) = @_;
  return $self->{'halfmove'} unless defined $halfmove;
  return unless halfmove_count_valid($halfmove);
  $self->{'halfmove'} = $halfmove;
  return 1;
}

sub move_number {
  my ($self,$move) = @_;
  return $self->{'move'} unless defined $move;
  return unless move_number_valid($move);
  $self->{'move'} = $move;
  return 1;
}

sub player_to_move {
  my ($self,$colour) = @_;
  return $self->{'player_to_move'} unless defined $colour;
  return unless colour_valid($colour);
  $self->{'player_to_move'} = $colour;
  return 1;
}

my @CASTLE_TESTS = 
  (
   [ &WHITE, &KING,  { 'e1' => 'K', 'h1' => 'R' } ],
   [ &WHITE, &QUEEN, { 'e1' => 'K', 'a1' => 'R' } ],
   [ &BLACK, &KING,  { 'e8' => 'k', 'h8' => 'r' } ],
   [ &BLACK, &QUEEN, { 'e8' => 'k', 'a8' => 'r' } ],
  );

sub validate ( $ ) {
  my ($self) = @_;
  my (%n,%m);
  @n{split '', $PIECE_CODES} = (0) x 13;
  @m{split '', $PIECE_CODES} = (0) x 13;
  
  # Count the number of each type of piece.
  foreach my $x (0 .. 7) {
    foreach my $y (0 .. 7) {
      ++$n{$self->at($x,$y)->code};
    }
    ++$m{$self->at($x,0)->code};
    ++$m{$self->at($x,7)->code};
  }
  
  # More than 8 pawns per side?
  $n{p} <= 8 or return error("Black has $n{p} pawns");
  $n{P} <= 8 or return error("White has $n{P} pawns");
  
  # Pawn + promoted piece count plausible?
  ($n{'p'} + (2<$n{'n'} ? $n{'n'}-2 : 0) + (2<$n{'b'} ? $n{'b'}-2 : 0)
   + (2<$n{'r'} ? $n{'r'}-2 : 0) + (1<$n{'q'} ? $n{'q'}-1 : 0) <= 8)
    or return error("Black has more than 8 pawns plus promoted pieces");
  ($n{'P'} + (2<$n{'N'} ? $n{'N'}-2 : 0) + (2<$n{'B'} ? $n{'B'}-2 : 0)
   + (2<$n{'R'} ? $n{'R'}-2 : 0) + (1<$n{'Q'} ? $n{'Q'}-1 : 0) <= 8)
    or return error("White has more than 8 pawns plus promoted pieces");
  
  # Not exactly 1 king per side?
  $n{'k'} == 1 or return error("Black has $n{'k'} kings");
  $n{'K'} == 1 or return error("White has $n{'K'} kings");
  
  # Pawns on ranks 1 or 8?
  $m{'p'} == 0 or return error("Black has a pawn on rank 1 or rank 8");
  $m{'P'} == 0 or return error("White has a pawn on rank 1 or rank 8");

  # Impossible en passant target square?
  my $ep = $self->{'en_passant'};
  if ($ep) {
    if ($self->{'player_to_move'} == &WHITE) {
      $ep->[1] == 5 or return
	error("White to move but EP square is @$ep");
      $self->at($ep->[0],6)->code == ' ' or return
	error("EP square is @$ep but rank 7 is not empty");
      $self->at($ep->[0],5)->code == ' ' or return
	error("EP square is @$ep but is not empty");
      $self->at($ep->[0],4)->code == 'p' or return
	error("EP square is @$ep but rank 5 does not contain a black pawn");
    } else {
      $ep->[1] == 2 or return
	error("Black to move but EP square is @$ep");
      $self->at($ep->[0],1)->code == ' ' or return
	error("EP square is @$ep but rank 2 is not empty");
      $self->at($ep->[0],2)->code == ' ' or return
	error("EP square is @$ep but is not empty");
      $self->at($ep->[0],3)->code == 'P' or return
	error("EP square is @$ep but rank 4 does not contain a white pawn");
    }
  }
   
  # Castling availability inconsistent with position?
  foreach my $c (@CASTLE_TESTS) {
    my $p = Games::Chess::Piece->new($c->[0], $c->[1]);
    if ($self->can_castle($c->[0], $c->[1])) {
      foreach my $sq (keys %{$c->[2]}) {
	my $colour = $p->colour_name;
	my $side = $p->piece_name;
	my $required = $c->[2]{$sq};
	my $req_name = Games::Chess::Piece->new($required)->piece_name;
	$self->at(algebraic_to_xy($sq))->code eq $required or return
	  error("$colour can castle ${side}side but no $req_name on $sq");
      }
    }
  }
  
  # Check halfmove count and move number.
  my $h = $self->{'halfmove'};
  0 <= $h or return error("Negative halfmove count $h");
  $h == int $h or return error("Non-integer halfmove count $h");
  $h <= 50 or return error("Halfmove count $h > 50: game should have drawn");
  my $m = $self->{'move'};
  1 <= $m or return error("Move number $m not positive");
  $m == int $m or return error("Non-integer move count $m");
  
  # Everything checks out OK.
  return 1;
}

#------------------------------------------------------------------------------
# Output Games::Chess::Position in varying formats.
#------------------------------------------------------------------------------

sub to_FEN ( $ ) {
  my ($self) = @_;
  my $position = join '/', map {
    my $y = $_;
    my $rank = join '', map { $self->at($_,$y)->code } 0 .. 7;
    $rank =~ s/( +)/length $1/eg;
    $rank;
  } reverse 0 .. 7;
  return join ' ',
  ( $position,
    ( $self->{'player_to_move'} == &BLACK ? 'b' : 'w'),
    ( join '', sort keys %{$self->{'can_castle'}} or '-' ),
    ( defined $self->{'en_passant'}
      ? xy_to_algebraic(@{$self->{'en_passant'}}) : '-' ),
    $self->{'halfmove'},
    $self->{'move'} );
}

sub to_text ( $ ) {
  my ($self) = @_;
  join "\n", map {
    my $y = $_;
    join ' ', map {
      my $sq = $self->at($_,$y)->code;
      $sq = '.' if $sq eq ' ' and ($y + $_) % 2 == 0;
      $sq;
    } 0 .. 7;
  } reverse 0 .. 7;
}

# Width and height of the GIF images for the pieces.
my ($width,$height) = (33,33);

sub to_GIF ( $ ) {
  my ($self) = shift;
  require GD;
  my %opts = ( lmargin => 20, bmargin => 20, border => 2,
	       font => GD::Font->Giant, letters => 1, @_ );

  # Check options.
  $opts{lmargin} = $opts{bmargin} = 0 unless $opts{letters};
  foreach (qw(lmargin bmargin border)) {
    0 <= $opts{$_} or return error("Option $_ $opts{$_} must be >= 0.");
  }
  UNIVERSAL::isa($opts{font}, 'GD::Font')
    or return error("$opts{font} does not belong to the GD::Font class.");

  # Image parameters:
  #     $iwidth		Total image width
  #     $iheight	Total image height
  my ($iwidth, $iheight) = ($opts{lmargin} + 8 * $width + 2 * $opts{border},
			    8 * $height + $opts{bmargin} + 2 * $opts{border});
  my $img = GD::Image->new($iwidth, $iheight);

  # Colours:
  #	$white		White squares on the chess board
  #	$grey		Black squares on the chess board
  #	$black		The border and the lettering
  #	$transparent	The margins
  my $white = $img->colorAllocate(255,255,255);
  my $grey  = $img->colorAllocate(191,191,191);
  my $black = $img->colorAllocate(0,0,0);
  my $transparent = $img->colorAllocate(255,192,192);
  $img->transparent($transparent);

  # Colour the board and the margins; draw a border round the board.
  $img->filledRectangle(0, 0, $iwidth-1, $iheight-1, $transparent);
  $img->filledRectangle($opts{lmargin}, 0, $iwidth-1,
			$iheight-1-$opts{bmargin}, $white);
  for (my $i = 0; $i < $opts{border}; ++$i) {
    $img->rectangle($opts{lmargin} + $i, $i, $iwidth - 1 - $i,
		    $iheight - 1 - $opts{bmargin} - $i, $black);
  }

  # Draw the file letters a-h and the rank numbers 1-8.
  if ($opts{letters}) {
    my ($fw,$fh) = ($opts{font}->width, $opts{font}->height);
    foreach my $n (0 .. 7) {
      $img->string($opts{font}, ($opts{lmargin} - $fw) / 2,
		   $opts{border} + $n * $height + ($height - $fh) / 2,
		   8 - $n, $black);
      $img->string($opts{font},
		   $opts{lmargin} + $opts{border} + $n*$width + ($width-$fw)/2,
		   $iheight - $opts{bmargin} + ($opts{bmargin}-$fh)/2,
		   chr(ord('a')+$n), $black);
    }
  }

  # Draw the backgrounds to the black squares and draw the pieces.
  my $gifs = piece_gifs();
  foreach my $x (0 .. 7) {
    foreach my $y (0 .. 7) {
      my ($left,$top) = ($opts{lmargin} + $opts{border} + $x * $width,
			 (7 - $y) * $height + $opts{border});
      $img->filledRectangle($left,$top,$left+$width-1,$top+$height-1,$grey)
	if ($x + $y) % 2 == 0;
      my $c = $self->at($x,$y)->code;
      next if $c eq ' ';
      $img->copy($gifs->{$c}, $left, $top, 0, 0, $width, $height);
    }
  }

  # Convert image to GIF and return.
  return $img->gif;
}

use vars '%gifs';

my %piece_images =
  ( 'p' => '5555555555555555555555555555555555555555ff75555555555555fff7555555555555dfff5555555555555fff7555555555555dfff5555555555555fff755555555555ffffff7555555555fffffff755555555ffffffff75555555fffffffff7555555dfffffffff5555555dffffffff5555555555dfff5555555555555fff7555555555555dfff555555555555dffff555555555555ffff755555555555dffff555555555555ffff755555555555dffff555555555555ffff755555555555dffff555555555555ffff75555555555dffffff555555555ffffffff75555555fffffffff7555555dfffffffff555555dffffffffff555555ffffffffff75555555555555555555555555555555555510',
    'n' => '5555555555555555555555f755555555555557df5555555555555dffff755555555555ffefff7555555555dfffffff555555555fffffaff55555555dfffffaef5555555dffffffaef5555555fffffffaef555555ffffffffaef55555dffffffffaef5555dffaffffffaf75555ffbefffffbaf7555ffffffffffbef555fffffffffffaef55ffffffffffffae75ffffffffffffbaf5dfffbffffffffbe75fbebfffffffffae5dffbf75dffffffaf5ff7f75dffffffbe75ffd75dfffffffaf555555dffffffffe755555fffffffffbf55555ffffffffffe75555dfffffffffbf5555dfffffffffff75555ffffffffffff5555dfffffffffff55555fffffffffff755555dfffffffff55555555555555555510',
    'b' => '55555555555555555555555f55f555555555555ff5ff55555555555df7df755555555555ff5ff55555555555dffff755555555555fffbf75555555555ffffaf7555555555ffffbaf555555555fffffbaf55555555dfffffbe75555555dffffffbe75555555fffffffaf5555555ffffffffa7555555dffffffffe5555555ffffffffb7555555dffffffffe5555555ffffffffb75555555fffffffff5555555dffffffff75555555ffffffff755555555ffaaaef755555555daaffbae555555555dffffff555555555dfffffff555555555ffaaaef755555555daaffbae555555fffeffffffeff755ffffffffffffff75fffffffffffffff7dfffffffffffffff5dfffff755ffffff5555555555555555510',
    'r' => '55555555555555555555555555555555555fff55df55dff7555dfff5dff5dfff5555ffffffffffff7555dffffffffffff5555ffffffffffff7555dffffffffffff55555ffffbaffff7555555dffaaaeff55555555fbaefaaf755555555beffffa755555555dfffffff555555555fffffff755555555dfffffff555555555fffffff755555555dfffffff555555555fffffff755555555dfffffff555555555fffffff755555555dfffffff555555555fffaeff755555555dfbaaaff55555555dfaafbaef5555555dbaffffbaf555555dffffffffff55555dfffffffffff5555dffffffffffff555dfffffffffffff55dffffffffffffff55ffffffffffffff75dffffffffffffff5555555555555555510',
    'q' => '555555555555555555555f75555f755555555ff7555ff75555555dff555dff55555555ff7555ff755555555f75555f755555555df5555df555555555f75555f755555555dff55dff555555555ff755ff75555f755dfffdfff555fff755fff7fff755ffff55dfffffff55dfff75fffffffff5dffdfffffffffffffff5dffffffffffffff55dfffffffffffff555ffffffaefffff755dfffbaaaaaffff555dfaaafffbaaef5555faffffffffbe75555fffffbfffff75555dffffbafffff55555fffffbfffff75555dfffffffffff55555fffffffffff75555dfffbaaaffff55555dfaaeffaaef555555faffffffbe755555dffffffffff555555dfffffffff55555555fffffff75555555555555555555510',
    'k' => '555555dfff555555555555dffff555555555555fabe755555555555dbeaf555555555555fbaf755555555555dbeaf555555555555fabe7555555dfff7dffff5ffff5dfffffffffffffffdffbafffbfffbafffffbeaeffeffaeeffffbefbeffffaffaffffaffaefffaefbefffbeffbfffbfffaffffbeffefffeffafffffbefbeffbffaffffffbffbffbefbfff7fffaffeffefbeff7dffbefbaaaffafff5dffbaaafbaaafff55dfbaefffffaaff555dfefffbffffef5555dffffbafffff55555dffffbfffff555555ffffffffff755555dffffffffff555555ffffbaffff755555dffbaaaafff555555faaaffbaae755555dffffffffff555555dfffffffff5555555dffffffff55555555dfffffff555510',
    'P' => '5555555555555555555555555555555555555555ff75555555555555fff7555555555555dbaf5555555555555fae7555555555555dbaf5555555555555fbf755555555555fffeff7555555555ffbaaff755555555fbaaaaaf75555555faaaaaaae7555555dfffffffff55555555ffffffff5555555555dfef5555555555555fbf7555555555555dbaf555555555555dfaef555555555555faae755555555555dbaaf555555555555faae755555555555dbaaf555555555555faae755555555555dfaef555555555555fbaf75555555555dffaeff555555555fffaaeff75555555ffaaaaaef7555555dbaaaaaaaf555555dffffffffff555555ffffffffff75555555555555555555555555555555555510',
    'N' => '5555555555555555555555f755555555555555df55555555555555dfff755555555555dfffff75555555555ffaffff555555555ffbaaeff55555555dfbaaaaff5555555dfaaaaaaef5555555fbaaaaaaef555555fbaaaaaaaef55555dbefaaaaaaf75555dfafbaaaaaaf75555faefaaaaaaef5555faaaaaaaaaaef555fbaaaaaaaaaae755fbaaaaaaaaaaaf75dbaaaaaebaaaaef5dbaaaffffaaaaae75feaaffffaaaaaaf5dbabf75dbaaaaaef5ffff75dfaaaaaaf75fff55dfaaaaaaaf555555dfaaaaaaae755555fbaaaaaaaef55555fbaaaaaaaaf75555dbaaaaaaaaef5555dfaaaaaaaaaf75555fbaaaaaaaaef5555dbaaffffbaaf55555fffffffffff755555dfffffffff55555555555555555510',
    'B' => '55555555555555555555555f55f555555555555ff5ff55555555555df7df755555555555ff5ff55555555555dffff755555555555fefff75555555555faefaf7555555555dbafbaf555555555fbaaebef55555555dbaaafbe75555555dfaaaafaf75555555faaaaafaf5555555fbaaaaefe7555555dbaaaaaebf5555555faaaaaaff7555555dbaaaaaaff5555555fbaaaaaef75555555faaaaaaff5555555dbaaaaaef75555555ffffffff755555555fffffff755555555dfaabaef555555555fbafbaf755555555dfaabaef555555555fffffff755555555dfffffff55555dfffffaaaefffff5dfffffefffefffff5baaaaeffffaaaaa7dfffffffffffffff5dfffff755ffffff5555555555555555510',
    'R' => '55555555555555555555555555555555555fff55df55dff7555dfff5dff5dfff5555faeffbafffae7555dbaafbaafbaaf5555faaaaaaaaaae7555dfbaaaaaaaaff55555fbaaefaaaf7555555dbafffbaf55555555fefbaffe755555555ffaaaef755555555dfaaaaef555555555faaaaae755555555dbaaaaaf555555555faaaaae755555555dbaaaaaf555555555faaaaae755555555dbaaaaaf555555555faaaaae755555555dbaefaaf555555555fafffbe755555555dffbafff55555555dffaaaeff5555555dfaaaaaaef555555dfaaaaaaaef55555dfaaaaaaaaef5555dfaaaaaaaaaef555dfaaaaaaaaaaef55dfaaaaaaaaaaaef55ffffffffffffff75dffffffffffffff5555555555555555510',
    'Q' => '555555555555555555555f75555f755555555ff7555ff75555555dbf555dbf55555555ff7555ff755555555f75555f755555555df5555df555555555f75555f755555555dff55dff555555555fe755fe75555f755dbffdfbf555fff755faf7fbe755ffbf55dbaffbaf55dbfff5dbaeffaaf5dffdffffaaefaaeffff5dfffbaaeaaaffff55dbfbaaaaaaaefe555fbaaaaaaaaaae755dfaaffffffbaef555dffffffffffff5555fffaaaaaaeff75555faaaaeaaaae75555dbaaaefaaaaf55555faaaaeaaaae75555dbaaaaaaaaaf55555faafffffbae75555dfffffffffff55555dffbaaaafff555555fbaaaaaaaf755555dffbaaaafff555555dfffffffff55555555fffffff75555555555555555555510',
    'K' => '555555dfff555555555555dffff555555555555ffff755555555555dfaef555555555555ffff755555555555dbfbf555555555555fefe7555555dfff7dffff5ffff5dffffffbafffffffdfbaafffffffbaafffbaaaefffffaaaaffbaaaaebaafaaaaaffaaaaaebafaaaaaefbaaaaafaebaaaaaffaaaaaababaaaaaefbaaaaaebfaaaaaaffbaaaaafebaaaaae7fbaaaaabbaaaaae7dfaaaaaefaaaaaef5dfaaeffffffaaaf55dfffffffffffff555dffbaaaaaafff5555dfaaaabaaaef55555dbaaafbaaaf555555faaaabaaae755555dbaaaaaaaaf555555faefffffbe755555dffffffffff555555fffaaaaaff755555dfaaaaaaaaf555555dfbaaaaaef5555555dffffffff55555555dfffffff555510',
  );

sub piece_gifs () {
  unless (%gifs) {
    # Create GIF image files for the 12 pieces.
    foreach my $code (keys %PIECE_CODES) {
      next if $code eq ' ';
      $gifs{$code} = GD::Image->new($width,$height);
      my $white = $gifs{$code}->colorAllocate(255,255,255);
      my $black = $gifs{$code}->colorAllocate(0,0,0);
      my $transparent = $gifs{$code}->colorAllocate(0,255,0);
      $gifs{$code}->transparent($transparent);
      my $v = pack('h*', $piece_images{$code});
      foreach my $x (0 .. $width-1) {
	foreach my $y (0 .. $width-1) {
	  $gifs{$code}->setPixel($x,$y,($transparent,$white,$black)
				 [vec($v, $y * 33 + $x, 2) - 1]);
	}
      }
    }
  }
  return \%gifs;
}

1;
