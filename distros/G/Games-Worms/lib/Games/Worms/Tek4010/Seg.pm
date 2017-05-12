package Games::Worms::Tek4010::Seg;
# Time-stamp: "1999-03-03 11:20:06 MST" -*-Perl-*-
use strict;
use vars qw($Debug $VERSION @ISA);
use Games::Worms::Seg;

$Debug = 0;
@ISA = ('Games::Worms::Seg');
$VERSION = "0.60";

sub draw { # possibly redraw
  my $it = shift;
  print &Games::Worms::Tek4010::tek_vector(@{$it->{'coords'}});
  # no color, you note.
}

1;

__END__
