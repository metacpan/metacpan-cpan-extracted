# Time-stamp: "1999-03-03 11:24:30 MST" -*-Perl-*-
package Games::Worms::Seg;
use strict;

use vars qw($Debug $VERSION);
$Debug = 0;
$VERSION = "0.60";

my $uid = 0;

sub new {
  my $c = shift;
  $c = ref($c) || $c;
  my $it = bless { @_ }, $c;

  $it->{'uid'} = $uid++; # per-session unique, if we need it
  $it->{'color'} = $it->{'board'}{'line_color'}
   if !exists($it->{'color'}) && $it->{'board'}{'line_color'};

#  $it->{'nodes'} ||= [0,0]; # the two nodes this segment connects

  return $it;
}

#sub nodes {
#  my $it = $_[0];
#  return @{$it->{'nodes'}};
#}

sub be_eaten {
  my $it = $_[0];
  $it->{'eaten'} = 1;
}

sub refresh {
  my $it = $_[0];
  $it->{'eaten'} = 0;
}

sub refresh_and_draw {
  my $it = $_[0];
  $it->{'eaten'} = 0;
  $it->draw;
}

sub is_eaten {
  my $it = $_[0];
  return $it->{'eaten'};
}

sub draw_new_at {
  my $c = shift;
  my @coords = splice @_,0,4;
  my $it = $c->new('coords' => \@coords, @_);
  print " Coords for $it: ", join(' ', @coords), "\n" if $Debug;
  $it->draw;
  return $it;
}

sub new_at {
  my $c = shift;
  my @coords = splice @_,0,4;
  my $it = $c->new('coords' => \@coords, @_);
  print " Coords for $it: ", join(' ', @coords), "\n" if $Debug;
  return $it;
}

# And we need a draw method.

1;

__END__

