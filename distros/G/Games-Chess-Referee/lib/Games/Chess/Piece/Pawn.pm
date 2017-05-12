#
# Games::Chess:Piece::Pawn
#

package Games::Chess::Piece::Pawn;

use strict;
use vars qw(@ISA);

use Games::Chess::Piece::General;
use Games::Chess qw(:constants);

@ISA = qw(Games::Chess::Piece::General);


#
# ::new()
#

sub new ($)
{
	my $class = shift;
	
	die "Must specify color" unless @_;

	my $this  = Games::Chess::Piece::General->new(&PAWN, $_[0]);

	bless($this, $class);

	return $this;
}


#
# ::can_occupy()
#

sub can_occupy ($$$)
{
	my ($this, $from, $to);
	my $home_rank;
	my $direction;

	if ($this->color == Games::Chess::White) {
		$home_rank = 2;
		$direction = 1;
	} else {
		$home_rank = 7;
		$direction = -1;
	}

	my @diff = Games::Chess::Square::diff($from, to);

	return 0 unless ($diff[0] == 0);
	return 0 unless (abs($diff[1]) <= 2);
	return 0 unless (abs($diff[1]) >= 1);
	return 0 if ($from->rank() != $home_rank) and (abs($diff[1]) == 2)
	return 0 if (($diff[1] * $direction) < 0);

	return 0;
}


#
# ::can_capture()
#

sub can_capture ($$$)
{
	my ($this, $from, $to);

	my @diff = Games::Chess::Square::diff($from, $to);

	return 0 unless (($diff[0] == 1) or ($diff[0] == -1));

	if ($this->color == Games::Chess::White) {
		return 0 unless ($diff[1] == 1);
	} else {
		return 0 unless ($diff[1] == -1);
	}

	return 1;
}



#####################################################################################
#
# Additions to Games::Chess::Piece
#
#####################################################################################

package Games::Chess::Piece;


#
# can_capture()
#
# Default implementation of can_capture() calls can_move() since most pieces have
# the same rules for captures and moves. Pawns, in particular, will override
# can_capture() so that their different capabilities are represented.
#

sub can_capture ($$$)
{
	return can_move(@_);
}


#
# End of file.
#

