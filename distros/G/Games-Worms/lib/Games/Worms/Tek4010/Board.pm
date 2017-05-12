# Time-stamp: "1999-03-03 11:21:43 MST" -*-Perl-*-
package Games::Worms::Tek4010::Board;
use strict;
use Games::Worms::Board;
use vars qw($Debug $VERSION %Default @ISA);
@ISA = ('Games::Worms::Board');
$VERSION = "0.60";
$Debug = 0;

#--------------------------------------------------------------------------
sub Seg  { return 'Games::Worms::Tek4010::Seg' }
sub Node { return 'Games::Worms::Node' }

#--------------------------------------------------------------------------

sub window_init {
  my $board = shift;

  $board->init_grid;
  #$board->refresh_and_draw_grid;
  return;
}

#--------------------------------------------------------------------------
1;

__END__
