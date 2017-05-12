package Games::Go::Cinderblock::State;
use Moose;
use Games::Go::Cinderblock::MoveResult;


# basilisk::state,
# long overdue.
# describes board pos, turn, caps, etc.
# serializable & deserializable.
# doesn't serialize ruleset...; dunno how to handle that. if at all.
has rulemap => (
   is => 'ro',
   isa => 'Games::Go::Cinderblock::Rulemap',
   required => 1,
);

has board => (
   isa => 'ArrayRef',
   is => 'rw',
);
has turn => (
   is => 'rw',
   isa => 'Str',
);
has _captures => (
   isa => 'HashRef',
   is => 'ro',
   default => sub{{w=>0,b=>0}},
);

around BUILDARGS => sub {
   my $orig  = shift;
   my $class = shift;
   my %args = @_;
   if($args{captures}){
      $args{_captures} = delete $args{captures};
   }
   return $class->$orig(%args);
};

sub attempt_move{
   my $self = shift;
   my %args = @_;
   my $success = 1;
   my $attempt = Games::Go::Cinderblock::MoveAttempt->new(
      basis_state => $self,
      rulemap => $self->rulemap,
      node => $args{node},
      color => $args{color},
      move_attempt => \%args,
   );
   my $result = $self->rulemap->evaluate_move_attempt($attempt);
   return $result;
}

sub scorable{ #new? args? scorable_from_json?
   my $self = shift;
   my $scorable = Games::Go::Cinderblock::Scorable->new(
      state => $self,
      rulemap => $self->rulemap,
   );
}

sub at_node{
   my ($self,$node) = @_;
   return $self->rulemap->stone_at_node($self->board,$node);
}

sub floodfill{
   my ($self, $cond, $progenitor) = @_;
   my $set = $self->rulemap->nodeset($progenitor);
   my $seen = $self->rulemap->nodeset($progenitor);
   my @q = $self->rulemap->adjacent_nodes($progenitor);
   my $unseen = $self->rulemap->nodeset(@q);
   local($_);
   while($unseen->count){
      my $node = $unseen->choose;
      $unseen->remove($node);
      $seen->add($node);
      #next if $seen->has_node($node);
      #$seen->add($node);
      $_ = $self->at_node($node);
      #warn ($_ ? @$_ : '');
      #Carp::confess;
      next unless $cond->($node);
      $set->add($node);
      for my $n ( $self->rulemap->adjacent_nodes($node)) {
         next if ($seen->has_node($n));
         $unseen->add($n);
      }
      #     push @q, $self->rulemap->adjacent_nodes($node);
   }
   return $set;
}


sub grep_nodeset{
   my ($self,$cond,$ns) = @_;
   my $new_ns = $self->rulemap->nodeset;
   local($_);
   for my $node ($ns->nodes){
      my $at = $self->at_node($node);
      $_ = $at;
      if($cond->()){
         $new_ns->add($node);
      }
   }
   return $new_ns;
}


sub num_colors_in_nodeset{
   my $self = shift;
   return scalar ($self->colors_in_nodeset(@_));
}
sub colors_in_nodeset{
   my ($self, $nodeset) = @_;
   my %colors;
   for my $node ($nodeset->nodes){
      my $stone = $self->at_node($node);
      next unless $stone;
      $colors{$stone}++;
   }
   return keys %colors;
}

sub captures{
   my ($self,$color) = @_;
   if($color){return $self->_captures->{$color} }
   return $self->_captures;
}

sub delta_to{
   my ($self, $to) = @_;
   my $delta = $self->rulemap->delta($self,$to);
   return $delta;
   # my %changes;
   # {board}, {turn}, {captures}
}
sub delta_from{
   my ($self,$from) = @_;
   return $from->delta_to($self);
}

1;

__END__

=head1 NAME

Games::Go::Cinderblock::State - A game state representation

=head1 SYNOPSIS

 my $rulemap = Games::Go::Cinderblock::Rulemap::Rect->new(
   w => 5,
   h => 3,
 );
 my $board = [
   [qw/0 w 0 b 0],
   [qw/w w 0 b b],
   [qw/0 w 0 b 0]
 ];
 my $state = Games::Go::Cinderblock::State->new(
   rulemap => $rulemap,
   board => $board,
   turn => 'b',
 );
 # b expertly fills in an eye
 my $move_result = $state->attempt_move(
   color => 'b',
   node => [2,4],
 );
 $state = $move_result->resulting_state;
 say "Current turn: ' . $state->turn;
 # Current turn: w

=head1 DESCRIPTION

Unless you want bad things to happen, do not modify the state directly
while using it as the basis of a scorable. States are generally immutable,
but you do have the power to change them directly. Don't, though.

Use attempt_move, instead. In the future, move attempts will have 
special categories for passes & other tricky shenanigans.

=head1 METHODS

=head2 attempt_move

Usage: C<< my $move_result = $state->attempt_move(node=>$node,color=>$color >>

Return a L<MoveResult|Games::Go::Cinderblock::MoveResult>, which contains
a resulting state if the move attempt is successful.

=head2 scorable

Returns a new L<Games::Go::Cinderblock::Scorable>
with this state as its basis.

=head2 floodfill

 # a chain of black stones, starting at [10,10].
 my $chain = $state->floodfill( sub{$_ eq 'b'}, [10,10]);

Usage: C<< my $nodeset = $state->floodfill($condition, $progenitor) >>

This returns a nodeset of connected nodes where the condition evaluates
to true, beginning at a progenitor node.

To get a chain of white stones starting at $node
    $state->floodfill( $sub{ $_ eq 'w' }, $node);

To get a region of empty space, starting at $node
    $state->floodfill( $sub{ ! $_ }, $node);

=head2 grep_nodeset

 my $not_larger_nodeset = $state->grep_nodeset(sub{$_ =~ /[wb]/}, $nodeset)

Another awkward functional thing.

=cut
