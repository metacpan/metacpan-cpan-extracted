#
# Games::Chess:Piece::General
#

use strict;


package Games::Chess::Piece::General;

use Games::Chess::Piece;

use vars qw(@ISA);

@ISA = qw(Games::Chess::Piece);


#
# ::new()
#

sub new ($)
{
	my $class = shift;

	my $this  = Games::Chess::Piece->new(@_);

	bless($this, $class);

	return $this;
}


#
# ::can_occupy()
#

sub can_occupy ($$$)
{
	return undef;
}


#
# ::can_capture()
#
# Default implementation of can_capture() calls can_move() since most pieces have
# the same rules for captures and moves. Pawns, in particular, will override
# can_capture() so that their different capabilities are represented.
#

sub can_capture ($$$)
{
	return can_occupy(@_);
}


#
# End of file.
#

