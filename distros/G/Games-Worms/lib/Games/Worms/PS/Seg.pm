package Games::Worms::PS::Seg;
use strict;
use vars qw($Debug $VERSION @ISA);
use Games::Worms::Seg;

$Debug = 0;
@ISA = ('Games::Worms::Seg');
$VERSION = "0.60";

sub draw { # possibly redraw
  my $it = shift;
  print &Games::Worms::PS::ps_vector(@{$it->{'coords'}});
  # no color, you note.
}

1;

__END__
