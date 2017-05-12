package Games::Go::Cinderblock::Rulemap;
use 5.14.0;
use Moose;

use Games::Go::Cinderblock::NodeSet;
use Games::Go::Cinderblock::Delta;
use Games::Go::Cinderblock::State;
use Games::Go::Cinderblock::Scorable;
use Games::Go::Cinderblock::MoveAttempt;
use Games::Go::Cinderblock::MoveResult;

use Games::Go::Cinderblock::Rulemap::Rect;
use List::MoreUtils qw/all/;

# This class evaluates moves and determines new board positions.
# This class stores no board/position data.
# Also, will must be used to determine visible portions of the board if there's fog of war.

# This class is basically here to define default behavior and
#   to provide a mechanism to override it.
# However this class will not handle rendering.

# Rulemaps are not stored in the database. They are derived from
#   entries in the Ruleset and Extra_rule tables. Or wherever.
# Some extra rules could be assigned using Moose's roles.
# Example: 'fog of war', 'atom go' each could be assigned to several variants.

# Also: This does not involve the ko rule. That requires a database search 
#   for a duplicate position. TODO:: B::History. Do this.

# Note: I'm treating intersections (i.e. nodes) as scalars, which different rulemap 
#   subclasses may handle as they will. Rect nodes [$row,$col].

#To support more than 2 players or sides, each game inherently has a sort of basis
# such as 'ffa', 'zen', 'team', 'perverse', or perhaps more

# Classes to extract:
# Games::Go::Cinderblock::State, (DONE)
# Games::Go::Cinderblock::MoveResult, (DONE, + MoveAttempt)
# Games::Go::Cinderblock::Scorable, (DONE)
# Games::Go::Cinderblock::Delta,
# Games::Go::Cinderblock::History?
# Games::Go::Cinderblock::TurmDeturninator?
# Games::Go::Cinderblock::NodeSet, (DONE)

has topology => (
   is => 'ro',
   isa => 'Str',
   default => 'plane'
);
has phase_description => (
   is => 'ro',
   isa => 'Str',
   default => '0b 1w'
);
has komi => (
   is => 'ro',
   isa => 'Num',
   default => '6.5'
);
has ko_rule => (
   is => 'ro',
   isa => 'Str',
   default => 'situational',
);

# to be extended to fog, atom, etc
sub FOO_apply_rule_role{
   my ($self, $rule, $param) = @_;
   if ($rule =~ /^heisengo/){
      Games::Go::Cinderblock::Rulemap::Heisengo::apply ($self, $param);
   }
   elsif ($rule =~ /^planckgo/){
      Games::Go::Cinderblock::Rulemap::Planckgo::apply ($self, $param);
   }
   else {die $rule} 
}


#These must be implemented in a subclass
my $blah = 'use a topo subclass such as ::Rect instead of Games::Go::Cinderblock::Rulemap';
sub move_is_valid{ die $blah}
sub node_to_string{ die $blah}
sub node_from_string{ die $blah}
sub node_liberties{ die $blah}
sub set_stone_at_node{ die $blah}
sub stone_at_node{ die $blah}
sub all_nodes{ die $blah}
sub copy_board{ die $blah}
sub empty_board{ die $blah}


sub initial_state{
   my $self = shift;
   my $state = Games::Go::Cinderblock::State->new(
      rulemap => $self,
      board => $self->empty_board,
      turn => 'b',
   );
   return $state;
}

sub normalize_board_to_string{ # to hash for ko collisions..
   my ($self,$board) = @_;
   my @all_nodes = $self->all_nodes;
   my @all_stones = map {$self->stone_at_node($board, $_) || 0} @all_nodes;
   return join '', @all_stones;
}
# use Carp::Always;

sub evaluate_move_attempt{
   my ($self, $move_attempt) = @_;
   my $basis = $move_attempt->basis_state;
   my $board = $basis->board;
   my $node = $move_attempt->node;
   my $color = $move_attempt->color;
   # my ($self, $board, $node, $color) = @_;
   die "bad color $color" unless $color=~ /^[bw]$/;
   die "bad node @$node" unless $self->node_is_valid($node);
  
   my %failure_template = (
      rulemap => $self,
      basis_state => $basis,
      move_attempt => $move_attempt,
      succeeded => 0, 
   );
   if ($self->stone_at_node ($board, $node)){
      return Games::Go::Cinderblock::MoveResult->new(
         %failure_template,
         reason => "stone exists at ". $self->node_to_string($node)
      ); 
   }
   if ($color ne $basis->turn){
      return Games::Go::Cinderblock::MoveResult->new(
         %failure_template,
         reason => "color $color (not) played during turn " .$basis->turn,
      ); 
   }
   
   #produce copy of board for evaluation -> add stone at $node
   my $newboard = $self->copy_board ($board);
   $self->set_stone_at_node ($newboard, $node, $color);
   # $chain is a list of strongly connected stones,
   # and $foes=enemies,$libs=liberties adjacent to $chain
   my ($chain, $libs, $foes) = $self->get_chain($newboard, $node);
   my $caps = $self->find_captured ($newboard, $foes);
   if (@$libs == 0 and @$caps == 0){
      return Games::Go::Cinderblock::MoveResult->new(
         rulemap => $self,
         basis_state => $basis,
         move_attempt => $move_attempt,
         succeeded => 0, 
         reason => "suicide",
      ); 
   }
   for my $cap(@$caps){ # just erase captured stones
      $self->set_stone_at_node ($newboard, $cap, 0);
   }
   my $other_color = (($color eq 'b') ? 'w' : 'b');
   my $res_stt = Games::Go::Cinderblock::State->new(
      rulemap => $self,
      board => $newboard,
      turn => $other_color,
      captures => {
         $color => $basis->captures->{$color} + @$caps,
         $other_color => $basis->captures->{$other_color},
      },
   );
   #return ($newboard, '', $caps);#no err
   return Games::Go::Cinderblock::MoveResult->new(
      rulemap => $self,
      basis_state => $basis,
      move_attempt => $move_attempt,
      succeeded => 1,
      caps => $caps,
      resulting_state => $res_stt,
   ); 
   #node is returned to make this method easier to override for heisenGo
}

#uses a floodfill algorithm, #TODO: absorb. generic.
#returns (string, liberties, adjacent_foes)
sub get_chain { #for all board types
   my ($self, $board, $node1) = @_; #start row/column
   
   my %seen; #indexed by stringified nodes
   my @found;
   my @libs; #liberties
   my @foes; #enemy stones adjacent to string
   my $string_side = $self->stone_at_node($board, $node1);
   return unless defined $string_side; #empty
   #0 has to mean empty, (b black, w white, ...)
   my @nodes = ($node1); #array of adjacent intersections to consider
   
   while (@nodes) {
      my $node = pop @nodes;
      next if $seen {$self->node_to_string ($node)};
      $seen {$self->node_to_string ($node)} = 1;
      
      my $here_side = $self->stone_at_node ($board, $node);
      
      unless ($here_side){ #empty
         push @libs, $node;
         next
      }
      if ($here_side eq $string_side){
         push @found, $node;
         push @nodes, $self->node_liberties ($node);
         next
      }
      # else enemy
      push @foes, $node;
   }
   return (\@found, \@libs, \@foes);
}


#chains are represented by a single 'delegate' node to identify chain
#returns chains, keyed by their delegates. a chain is a list of nodestrings
#also returns hash of {nodestring=>delegate} 
#also returns hash of {delegate=>side} 
sub FOO_all_chains{
   my ($self, $board) = @_;
   my %delegates;
   my %delegate_of_stone;
   my %delegate_side;
   for my $n ($self->all_stones($board)){
      my $s = $self->node_to_string($n);
      next if $delegate_of_stone{$s};
      
      $delegate_side{$s} = $self->stone_at_node($board, $n);
      my ($chain,$l,$f) = $self->get_chain($board, $n);
      #push @chains, $chain;
      #only deal with nodestrings here;
      $delegates{$s} =  [map {$self->node_to_string($_)} @$chain];
      my @nodestrings;
      #examine & to_string each node
      for (@$chain){
         my $nodestring =$self->node_to_string($_);
         push @nodestrings, $nodestring;
         $delegate_of_stone{$nodestring} = $s;
      }
   }
   return (\%delegates, \%delegate_of_stone, \%delegate_side)
}

sub nodeset{ # $rm->nodeset(@nodes)
   my $self = shift;
   my $ns = Games::Go::Cinderblock::NodeSet->new(rulemap => $self);
   $ns->add($_) for @_;
   return $ns;
}
# sub all_nodes, sub no_nodes.. TODO
sub all_nodes_nodeset{
   my $self = shift;
   return $self->nodeset($self->all_nodes);
}
sub FOO_floodfill{ #in state now..
   my ($self, $cond, $progenitor) = @_;
   my $set = $self->nodeset($progenitor);
   my $seen = $self->nodeset($progenitor);
   my @q = $self->adjacent_nodes($progenitor);
   while(@q){
      my $node = shift @q;
      next if $seen->has($node);
      $seen->add($node);
      next unless $cond->($node);
      $set->add($node);
      push @q, $self->adjacent_nodes($node);
   }
}


sub all_stones {
   my ($self, $board) = @_;
   return grep {$self->stone_at_node($board, $_)} ($self->all_nodes);
}

#opposite of get_chain
sub get_empty_space{
   my ($self, $board, $node1, $ignore_stones) = @_; #start row/column
   return ([],[]) if $self->stone_at_node ($board, $node1);
   $ignore_stones = {} unless $ignore_stones; #dead stones tend to be ignored when calculating territory
   
   my %seen; #indexed by stringified nodes
   my @found;
   my @adjacent_stones;
   my @nodes = ($node1); #array of adjacent intersections to consider
   while (@nodes) {
      my $node = pop @nodes;
      my $nodestring = $self->node_to_string ($node);
      next if $seen {$nodestring};
      $seen {$nodestring} = 1;
      
      my $here_color = $self->stone_at_node ($board, $node);
      if (!$here_color or $ignore_stones->{$nodestring}){ #empty
         push @found, $node;
         push @nodes, $self->node_liberties ($node)
      }
      else{ #stone
         push @adjacent_stones, $node;
      }
   }
   return (\@found, \@adjacent_stones);
}

# TODO: absorb into generic flood fill
#take a list of stones, returns those which have no libs, as chains
sub find_captured{
   my ($self, $board, $nodes) = @_;
   my @nodes = @$nodes; #list
   my %seen; #indexed by stringified node
   my @caps; #list
   while (@nodes){
      my $node = pop @nodes;
      next if $seen {$self->node_to_string($node)};
      my ($chain, $libs, $foes) = $self->get_chain ($board, $node);
      my $capture_these = scalar @$libs ? '0' : '1';
      for my $n (@$chain){
         $seen {$self->node_to_string($n)} = 1;
         push @caps, $n if $capture_these;
      }
   }
   return \@caps
}



sub side_of_entity{
   my ($self, $entity) = @_;
   die 'wrong score mode' unless $self->detect_basis eq 'ffa';
   for my $phase (split ' ', $self->phase_description) {
      if ($phase =~ m/$entity([wbr])/){
         return $1;
      }
   }
}
sub all_entities{
   my $self = shift;
   my $pd = $self->phase_description;
   my %e;
   while($pd=~/(\d)/g){
      $e{$1}=1
   }
   return keys %e;
}
sub all_sides{
   my $self = shift;
   my $pd = $self->phase_description;
   my %s;
   while($pd=~/([bw])/g){
      $s{$1}=1
   }
   return keys %s;
}

sub default_captures {#for before move 1
   my $self = shift;
   my @phases = split ' ', $self->phase_description;
   return join ' ', map {0} (1..@phases) #'0 0'
}


#Necessary to decide how to describe game in /game. 
#Score & game objectives depend.
#reads the phase description and
# returns 'ffa', 'team', 'zen', or 'perverse'? or 'other'?
sub detect_basis{
   my $self = shift; #is it a pd or a rulemap?
   my $pd = ref $self ? $self->phase_description : $self;
   
   #assume that this is well-formed
   #and no entity numbers are skipped
   my @phases = map {[split'',$_]} split ' ', $pd;
   my %ents;
   my %sides;
   for (@phases){
      $ents{$_->[0]}{$_->[1]} = 1;
      $sides{$_->[1]}{$_->[0]} = 1;
   }
   return 'ffa' if @phases == keys %ents
               and @phases == keys %sides;
   return 'zen' if all {keys %{$ents{$_}} == keys%sides} (keys%ents); 
   
   return 'other';
}

sub compute_score{
   my ($self, $board, $caps, $death_mask) = @_;
   my ($terr_mask, $terr_points) = $self->find_territory_mask($board, $death_mask);
   
   my $type = $self->detect_basis;
   my $pd = $self->phase_description;
   my @phases = split ' ', $pd;
   @phases = map {[split '', $_]} @phases;
   
   my @sides = $self->all_sides;
   my %side_score =  map {$_=>0} @sides;
   
   { #add up captures of each team.
      my @caps = split ' ', $caps; # from latest move
      for my $phase (@phases){
         my $phase_caps = shift @caps;
         $side_score{$phase->[1]} += $phase_caps;
      }
      #add up territory of each team.
      for my $side (@sides){
         $side_score{$side} += $terr_points->{$side};
      }
      #and count dead things in death_mask 
      #points in death_mask go to territory owner in terr_mask
      for my $d (keys %$death_mask){
         my $capturer = $terr_mask->{$d};
         if ($capturer){
            $side_score{$capturer}++;
         }
      }
   }
   
   if ($self->phase_description eq '0b 1w'){
      $side_score{w} += $self->komi;
   }
   
   if ($type eq 'ffa' or $type eq 'zen' or $type eq 'team'){
      return \%side_score
   }
   return  'perverse or other modes not scoring...'
}

sub num_phases{
   my ($self) = @_;
   my @phases = split ' ', $self->phase_description;
   return scalar @phases;
}

sub determine_next_phase{
   my ($self, $phase, $choice_phases) = @_;
   my $np = $self->num_phases;
   my $next = $phase;
   for (1..$np){
      $next = ($next + 1) % $np;
      return $next if grep {$next==$_} @$choice_phases;
   }
   die "I was given a bad list of choice phases: " . join',',@$choice_phases;
}


#compare earlier state to later state.
# package the things which actually change.
# among board, turn, & captures.

sub delta{
   my ($self,$state1,$state2) = @_;
   my %deltargs;

   my $board_changeset = $self->_compare_boards( $state1->board, $state2->board );
   $deltargs{board} = $board_changeset if %$board_changeset;
   if($state1->turn ne $state2->turn){
      $deltargs{turn} = {before=>$state1->turn,after=>$state2->turn};
   }
   if($state1->captures('w') != $state2->captures('w')){
      $deltargs{captures}{w} = {before=>$state1->captures('w'),after=>$state2->captures('w')};
   }
   if($state1->captures('b') != $state2->captures('b')){
      $deltargs{captures}{b} = {before=>$state1->captures('b'),after=>$state2->captures('b')};
   }

   my $delta = Games::Go::Cinderblock::Delta->new(
      rulemap => $self,
      %deltargs
   );
   return $delta;
}


#compare earlier board to later board.
sub _compare_boards{
   my ($self, $board1, $board2) = @_;
   
   my %changeset;
   for my $node ($self->all_nodes){
      my $fore = $self->stone_at_node($board1, $node); #0,w,b,etc
      my $afte = $self->stone_at_node($board2, $node);
      next if ($fore eq $afte);
      if($fore){
         # autovivify.
         push @{$changeset{remove}{$fore}}, $node;
      }
      if($afte){
         push @{$changeset{add}{$afte}}, $node;
      }
   }
   return \%changeset;
}

1;

__END__

=head1 NAME

Games::Go::Cinderblock::Rulemap - The beating heart of cinderblock.

=head1 SYNOPSIS

 my $rulemap = Games::Go::Cinderblock::Rulemap::Rect->new(
   w => 11,
   h => 8,
   wrap_h => 1,
   wrap_v => 1,
 );
 my $state = $rulemap->initial_state;
 my $move_result = $state->attempt_move(
   color => 'b',
   node => [3,3],
 );
 say $move_result->succeeded ? 'success!' : ('failed? ' . $move_result->reason);
 $state = $move_result->resulting_state;
 # do something with $move_result->delta.

=head1 DESCRIPTION

This module is basically basilisk::Rulemap, now mostly split 
into a bunch of helper modules. The intention is still to use 
Moose's metaclass capabilities & method modifiers to override
aspects of the default behavior.

This class still uses subclasses to define topology, and still
only one topology is in a usable state: 
L<Games::Go::Cinderblock::Rulemap::Rect>.

=head1 METHODS

=head2 initial_state

=head2 nodeset

=head2 empty_board

=head2 all_nodes

=cut
