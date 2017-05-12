package Games::Worms::Node;
 # class that encapsulates nodes, i.e., where segments intersect
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
  $it->{'segments_toward'} ||= [0, 0, 0, 0, 0, 0,];
  $it->{'nodes_toward'} ||= [0, 0, 0, 0, 0, 0,];

  return $it;
}

sub segments_away {
  my $it = $_[0];
  return @{$it->{'segments_toward'}};
}

sub nodes_away {
  my $it = $_[0];
  return @{$it->{'segments_toward'}};
}

sub toward { # usage: "seg" or "node", direction
  my($it, $item, $dir) = @_[0,1,2];
  die "1st arg to Node->toward(item_kind, direction) isn't an item_kind"
   unless $item eq 'seg' or $item eq 'node';
  my $dir_list =  $it->{$item eq 'seg' ? 'segments_toward' : 'nodes_toward'};
  return $dir_list->[$dir % 6];
}


1;

