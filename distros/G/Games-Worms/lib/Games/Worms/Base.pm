package Games::Worms::Base;
 # base class for worms
use strict;

=head1 NAME

Games::Worms::Base -- base class for worms

=head1 SYNOPSIS

  package Spunky;
  use Games::Worms::Random;
  @ISA = ('Games::Worms::Random');
  ...stuff...

=head1 DESCRIPTION

This is the base class for all worms in Worms.

=cut

use vars qw($Debug $VERSION @Colors $Color_counter $Directions);
$Debug = 0;
$VERSION = "0.60";
$Directions = 6; # number of directions in this universe

my $uid = 0;

$Color_counter = 0;
@Colors = qw(red green blue yellow white orange);

#--------------------------------------------------------------------------

sub default_color {
  my $color = $Color_counter++;
  $Color_counter = 0 if $Color_counter > $#Colors;
  return $Colors[$color];
}

#--------------------------------------------------------------------------

sub init {
  return;
}

#--------------------------------------------------------------------------

sub initial_move {
  return int(rand($Directions));
}

sub can_zombie { 0 }
 # override with sub can_zombie { 1 } in a class that can be zombies

#--------------------------------------------------------------------------

sub try_move {
  my $worm = $_[0];
  return unless $worm->is_alive;
  if($Debug > 2) {
    sleep 1;
  }

  my $current_node = $worm->{'current_node'};

  my(%dir_2_uneaten_seg);
  my $i;
  foreach my $seg ($current_node->segments_away) {
    $dir_2_uneaten_seg{$i++} = $seg;
  }
  # was: @dir_2_uneaten_seg{0,1,2,3,4,5} = $current_node->segments_away;

  my $origin_direction = 0;

  foreach my $d (sort keys %dir_2_uneaten_seg) {
    # Is this the direction I got here by?
    if($dir_2_uneaten_seg{$d} eq $worm->{'last_segment_eaten'}) {
      $origin_direction = $d;
    }

    if($dir_2_uneaten_seg{$d}->is_eaten) {
      # print " Direction $d is no good ($dir_2_uneaten_seg{$d} is eaten)\n" if $Debug;
      delete $dir_2_uneaten_seg{$d};
    } else {
      # print " Direction $d is okay\n" if $Debug;
    }
  }

  unless(keys(%dir_2_uneaten_seg)) {
    print
     " worm $worm->{'name'} is stuck, from direction $origin_direction\n" 
     if $Debug;
    $worm->die;
    return 0;
  }

  my %rel_dir_2_uneaten_seg;
  my @rel_directions = (0) x $Directions;
  @rel_dir_2_uneaten_seg{ map {($_ - $origin_direction) % $Directions}
                              keys(%dir_2_uneaten_seg)
                        }
                        = values(%dir_2_uneaten_seg);
  foreach my $rd (keys(%rel_dir_2_uneaten_seg)) {
    $rel_directions[$rd] = 1;
  } # a 1 in this list means a FREE (uneaten) node

  if($Debug > 1) {
    my $adirs = join '', keys %dir_2_uneaten_seg;
    my $rdirs = join '', keys %rel_dir_2_uneaten_seg;
    print " worm $worm->{'name'} can go ",
      scalar(keys(%dir_2_uneaten_seg)),
      " ways (R$rdirs A$adirs), from dir $origin_direction\n"
     if $Debug > 1;
  }

  my $context = join('', @rel_directions);

  my $rel_dir_to_move;
  if($worm->{'memoize'} && defined($worm->{'memory'}{$context})) {
    $rel_dir_to_move = $worm->{'memory'}{$context};
  } else {
    if(keys(%dir_2_uneaten_seg) == $Directions) { # new worm
      $rel_dir_to_move =
	$worm->initial_move(\%rel_dir_2_uneaten_seg, \@rel_directions, $context);
    } elsif(keys(%dir_2_uneaten_seg) == 1) {
      $rel_dir_to_move = (keys(%rel_dir_2_uneaten_seg))[0];
    } else {
      $rel_dir_to_move =
	$worm->which_way(\%rel_dir_2_uneaten_seg, \@rel_directions, $context);
    }
    $worm->{'memory'}{$context} = $rel_dir_to_move if $worm->{'memoize'};
  }

  # now unrelativize
  my $dir_to_move = ($rel_dir_to_move + $origin_direction) % $Directions;
  print
    "  worm $worm->{'name'} goes in R$rel_dir_to_move (D$dir_to_move)\n"
   if $Debug > 1;

  my $segment_to_eat = $dir_2_uneaten_seg{$dir_to_move};
  my $destination_node = $current_node->toward('node', $dir_to_move);
  
  $worm->eat_segment($segment_to_eat);

  $current_node = $worm->{'current_node'} = $destination_node;

  return 1;
}

#--------------------------------------------------------------------------
#
# You probably don't want to mess with the methods below here.
#

sub is_undead {  # read-only method
  my $it = $_[0];
  return $it->{'is_undead'};
}

sub be_undead { # set the undead attrib to 1
  my $it = $_[0];
  $it->{'last_segment_eaten'} = 0;
  $it->{'is_undead'} = 1;
}

sub be_not_undead { # set the undead attrib to 0
  my $it = $_[0];
  $it->{'last_segment_eaten'} = 0;
  $it->{'is_undead'} = 0;
}

#--------------------------------------------------------------------------

sub new {
  my $c = shift;
  $c = ref($c) || $c;
  my $it = bless { @_ }, $c;

  $it->{'uid'} = $uid++; # per-session unique, if we need it
  $it->{'is_alive'} = 1 unless defined $it->{'is_alive'};
  $it->{'color'} ||= $it->default_color;
  $it->{'segments_eaten'} = 0;
  $it->{'last_segment_eaten'} = 0;
  $it->{'memoize'} = $it->am_memoized;
  $it->{'can_zombie'} = $it->can_zombie;
  $it->{'is_undead'} = 1 unless defined $it->{'is_undead'};
  $it->{'memory'} = {};

  $it->init;

  push @{$it->{'board'}{'worms'}}, $it if $it->{'board'};
   # if I have a board set, put me in that board's worms list.
  print "New worm $it ($it->{'name'})\n" if $Debug;

  return $it;
}

sub am_memoized { 1; }
  # to block memoization, override with: sub am_memoized { 0; }

sub segments_eaten {
  my $it = $_[0];
  return $it->{'segments_eaten'};
}

sub is_alive { # regardless of whether undead or not
  my $it = $_[0];
  return $it->{'is_alive'};
}

#sub current_node {
#  my $it = $_[0];
#  return $it->{'current_node'};
#}

sub die {  # kill this worm.
  my $worm = $_[0];
  print " worm $worm dies\n" if $Debug;
  $worm->{'is_alive'} = 0;
  $worm->{'is_undead'} = 0;
}

sub really_die {  # kill this worm DEAD.
  my $worm = $_[0];
  print " worm $worm really dies\n" if $Debug;
  $worm->{'is_alive'} = 0;
  $worm->{'is_undead'} = 0;
}


sub eat_segment {
  my($worm, $segment) = @_[0,1];
  $worm->{'segments_eaten'}++;
  $worm->{'last_segment_eaten'} = $segment;

  if($worm->{'is_undead'}) {
    $segment->{'color'} = $worm->{'color'};
    $segment->be_eaten;
    $segment->draw;
  } else {
    $segment->{'color'} = $worm->{'color'};
    $segment->refresh;
  }

  # make a SEG->be_eaten_by(WORM) and SEG->be_restored_by(WORM)

  # print " worm $worm eats segment $segment\n" if $Debug;

  return;
}

#--------------------------------------------------------------------------

1;

__END__

