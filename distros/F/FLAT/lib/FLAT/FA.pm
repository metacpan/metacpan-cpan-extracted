package FLAT::FA;

use strict;
use base 'FLAT';
use Carp;

use FLAT::Transition;

=head1 NAME

FLAT::FA - Base class for regular finite automata

=head1 SYNOPSIS

A FLAT::FA object is a collection of states and transitions. Each state
may be labeled as starting or accepting. Each transition between states
is labeled with a transition object.

=head1 USAGE

FLAT::FA is a superclass that is not intended to be used directly. However,
it does provide the following methods:

=cut

sub new {
    my $pkg = shift;
    bless {
        STATES => [],
        TRANS  => [],
        ALPHA  => {}
    }, $pkg;
}

sub get_states {
    my $self = shift;
    return 0 .. ($self->num_states - 1);
}

sub num_states {
    my $self = shift;
    return scalar @{ $self->{STATES} };
}

sub is_state {
    my ($self, $state) = @_;
    exists $self->{STATES}->[$state];
}

sub _assert_states {
    my ($self, @states) = @_;
    for (@states) {
        croak "'$_' is not a state" if not $self->is_state($_);
    }
}
sub _assert_non_states {
    my ($self, @states) = @_;
    for (@states) {
        croak "There is already a state called '$_'" if $self->is_state($_);    
    }
}

sub delete_states {
    my ($self, @states) = @_;
    
    $self->_assert_states(@states);

    for my $s ( sort { $b <=> $a } @states ) {
        $self->_decr_alphabet($_)
            for @{ splice @{ $self->{TRANS} }, $s, 1  };

        $self->_decr_alphabet( splice @$_, $s, 1 )
            for @{ $self->{TRANS} };
            
        splice @{ $self->{STATES} }, $s, 1;
    }
}

sub add_states {
    my ($self, $num) = @_;
    my $id = $self->num_states;
    
    for my $s ( $id .. ($id+$num-1) ) {
        push @$_, undef for @{ $self->{TRANS} };
        push @{ $self->{TRANS} }, [ (undef) x ($s+1) ];
        push @{ $self->{STATES} }, {
            starting => 0,
            accepting => 0
        };
    }
    
    return wantarray ? ($id .. ($id+$num-1))
                     : $id+$num-1;
}

##############

sub is_starting {
    my ($self, $state) = @_;
    $self->_assert_states($state);
    return $self->{STATES}[$state]{starting};
}
sub set_starting {
    my ($self, @states) = @_;
    $self->_assert_states(@states);
    $self->{STATES}[$_]{starting} = 1 for @states;
}
sub unset_starting {
    my ($self, @states) = @_;
    $self->_assert_states(@states);
    $self->{STATES}[$_]{starting} = 0 for @states;
}
sub get_starting {
    my $self = shift;
    return grep { $self->is_starting($_) } $self->get_states;
}

##############

sub is_accepting {
    my ($self, $state) = @_;
    $self->_assert_states($state);
    return $self->{STATES}[$state]{accepting};
}
sub set_accepting {
    my ($self, @states) = @_;
    $self->_assert_states(@states);
    $self->{STATES}[$_]{accepting} = 1 for @states;
}
sub unset_accepting {
    my ($self, @states) = @_;
    $self->_assert_states(@states);
    $self->{STATES}[$_]{accepting} = 0 for @states;
}
sub get_accepting {
    my $self = shift;
    return grep { $self->is_accepting($_) } $self->get_states;
}

###############

sub _decr_alphabet {
    my ($self, $t) = @_;
    return if not defined $t;
    for ($t->alphabet) {
        delete $self->{ALPHA}{$_} if not --$self->{ALPHA}{$_};
    }
}
sub _incr_alphabet {
    my ($self, $t) = @_;
    return if not defined $t;
    $self->{ALPHA}{$_}++ for $t->alphabet;
}

sub set_transition {
    my ($self, $state1, $state2, @label) = @_;
    $self->remove_transition($state1, $state2);

    @label = grep defined, @label;
    return if not @label;
    
    my $t = $self->{TRANS_CLASS}->new(@label);
    $self->_incr_alphabet($t);

    $self->{TRANS}[$state1][$state2] = $t;
}

sub add_transition {
    my ($self, $state1, $state2, @label) = @_;

    @label = grep defined, @label;
    return if not @label;

    my $t = $self->get_transition($state1, $state2);
    $self->_decr_alphabet($t);
    
    if (!$t) {
        $t = $self->{TRANS}[$state1][$state2] = $self->{TRANS_CLASS}->new;
    }
    
    $t->add(@label);
    $self->_incr_alphabet($t);
}

sub get_transition {
    my ($self, $state1, $state2) = @_;
    $self->_assert_states($state1, $state2);
    
    $self->{TRANS}[$state1][$state2];
}

sub remove_transition {
    my ($self, $state1, $state2) = @_;

    $self->_decr_alphabet( $self->{TRANS}[$state1][$state2] );
    $self->{TRANS}[$state1][$state2] = undef;
}

# given a state and a symbol, it tells you 
# what the next state(s) are; do get successors 
# for find the successors for a set of symbols, 
# use array refs.  For example:
# @NEXT=$self->successors([@nodes],[@symbols]);
sub successors {
    my ($self, $state, $symb) = @_;
    
    my @states = ref $state eq 'ARRAY' ? @$state : ($state);
    my @symbs  = defined $symb
                  ? (ref $symb  eq 'ARRAY' ? @$symb  : ($symb))
                  : ();
        
    $self->_assert_states(@states);
    
    my %succ;
    for my $s (@states) {
        $succ{$_}++
            for grep { my $t = $self->{TRANS}[$s][$_];
                       defined $t && (@symbs ? $t->does(@symbs) : 1) } $self->get_states;
    }
    
    return keys %succ;
}

sub predecessors {
    my $self = shift;
    $self->clone->reverse->successors(@_);
}

# reverse  - no change from NFA
sub reverse {
    my $self = $_[0]->clone;
    $self->_transpose;
    
    my @start = $self->get_starting;
    my @final = $self->get_accepting;
    
    $self->unset_accepting( $self->get_states );
    $self->unset_starting( $self->get_states );
    
    $self->set_accepting( @start );
    $self->set_starting( @final );
    
    $self;
}

# get an array of all symbols
sub alphabet {
    my $self = shift;
    grep length, keys %{ $self->{ALPHA} };
}

# give an array of symbols, return the symbols that
# are in the alphabet
#sub is_in_alphabet {
#  my $self = shift;
#  my $
#}

############
sub prune {
    my $self = shift;
    
    my @queue = $self->get_starting;
    my %seen  = map { $_ => 1 } @queue;
    
    while (@queue) {
        @queue = grep { ! $seen{$_}++ } $self->successors(\@queue);
    }
    
    my @useless = grep { !$seen{$_} } $self->get_states;
    $self->delete_states(@useless);
    
    return @useless;
}


############

use Storable 'dclone';
sub clone {
    dclone( $_[0] );
}

sub _transpose {
    my $self = shift;
    my $N = $self->num_states - 1;
    
    $self->{TRANS} = [
        map {
            my $row = $_; 
            [ map { $_->[$row] } @{$self->{TRANS}} ]
        } 0 .. $N
    ];
}

# tests to see if set1 is a subset of set2
sub array_is_subset {
  my $self = shift;
  my $set1 = shift;
  my $set2 = shift;
  my $ok = 1;
  my %setcount = ();
  foreach ($self->array_unique(@{$set1}),$self->array_unique(@{$set2})) {
    $setcount{$_}++;
  }
  foreach ($self->array_unique(@{$set1})) {
    if ($setcount{$_} != 2) {
      $ok = 0;
      last;
    }
  }
  return $ok;
}

sub array_unique {
  my $self = shift;
  my %ret = ();
  foreach (@_) {
    $ret{$_}++;
  }
  return keys(%ret);
}

sub  array_complement {
  my $self = shift;
  my $set1 = shift;
  my $set2 = shift;
  my @ret = ();
  # convert set1 to a hash
  my %set1hash = map {$_ => 1} @{$set1};
  # iterate of set2 and test if $set1
  foreach (@{$set2}) {
    if (!defined $set1hash{$_}) {
      push(@ret,$_);
    }
  }
  ## Now do the same using $set2
  # convert set2 to a hash
  my %set2hash = map {$_ => 1} @{$set2};
  # iterate of set1 and test if $set1
  foreach (@{$set1}) {
    if (!defined $set2hash{$_}) {
      push(@ret,$_);
    }
  }
  # now @ret contains all items in $set1 not in $set 2 and all
  # items in $set2 not in $set1
  return @ret;  
}

# returns all items that 2 arrays have in common
sub array_intersect {
  my $self = shift;
  my $set1 = shift;
  my $set2 = shift;
  my %setcount = ();
  my @ret = ();
  foreach ($self->array_unique(@{$set1})) {
    $setcount{$_}++;
  }
  foreach ($self->array_unique(@{$set2})) {
    $setcount{$_}++;
    push(@ret,$_) if ($setcount{$_} > 1); 
  }
  return @ret;
}

# given a set of symbols, returns only the valid ones
sub get_valid_symbols {
  my $self = shift;
  my $symbols = shift;
  return $self->array_intersect([$self->alphabet()],[@{$symbols}])
}

## add an FA's states & transitions to this FA (as disjoint union)
sub _swallow {
    my ($self, $other) = @_;
    my $N1 = $self->num_states;
    my $N2 = $other->num_states;
    
    push @$_, (undef) x $N2
        for @{ $self->{TRANS} };

    push @{ $self->{TRANS} }, [ (undef) x $N1, @{ clone $_ } ]
        for @{ $other->{TRANS} };

    push @{ $self->{STATES} }, @{ clone $other->{STATES} };
    
    $self->{ALPHA}{$_} += $other->{ALPHA}{$_}
        for keys %{ $other->{ALPHA} };
    
    return map { $_ + $N1 } $other->get_states;
}

1;

__END__


=head2 Manipulation & Inspection Of States

=over

=item $fa-E<gt>get_states

Returns a list of all the state "names" in $fa.

=item $fa-E<gt>num_states

Returns the number of states in $fa.

=item $fa-E<gt>is_state($state_id)

Returns a boolean indicating whether $state_id is a recognized state "name."

=item $fa-E<gt>delete_states(@states)

Deletes the states given in @states and their corresponding transitions. The
remaining states in the FA may be "renamed" (renumbered)! Return value not
used.

=item $fa-E<gt>add_states($num)

Adds $num states to $fa, and returns a list of the new state "names."

=item $fa-E<gt>get_starting

=item $fa-E<gt>get_accepting

Returns a list of all the states which are labeled as starting/accepting,
respectively.

=item $fa-E<gt>set_accepting(@states)

=item $fa-E<gt>unset_accepting(@states)

=item $fa-E<gt>set_starting(@states)

=item $fa-E<gt>unset_starting(@states)

Sets/unsets a list of states as being labeled starting/accepting,
respectively.

=item $fa-E<gt>is_starting($state)

=item $fa-E<gt>is_accepting($state)

Returns a boolean indicating whether $state is labeled as starting/accepting,
respectively.

=item $fa-E<gt>prune

Deletes the states which are not reachable (via zero or more transitions)
from starting states. Returns a list of the "names" of states that were
deleted.

=back

=head2 Manipulation & Inspection Of Transitions

Each transition between states is a transition object, which knows how
to organize several "labels." Think of this as the mechanism by which
multiple arrows in the state diagram between the same states are collapsed
to a single arrow. This interface is abstracted away into the following
public methods:

=over

=item $fa-E<gt>set_transition($state1, $state2, @labels)

Resets the transition between $state1 and $state2 to a transition
initialized using data @labels. If @labels is omitted or contains
only undefined elements, then the call is equivalent to C<remove_transition>.

=item $fa-E<gt>add_transition($state1, $state2, @labels)

Adds @labels to the transition between $state1 and $state2.

=item $fa-E<gt>get_transition($state1, $state2)

Returns the transition object stored between $state1 and $state2, or
undef if there is no transition.

=item $fa-E<gt>remove_transition($state1, $state2)

Removes the transition object between $state1 and $state2.

=item $fa-E<gt>successors(\@states)

=item $fa-E<gt>successors($state)

=item $fa-E<gt>successors(\@states, $label)

=item $fa-E<gt>successors($state, $label)

=item $fa-E<gt>successors(\@states, \@labels)

=item $fa-E<gt>successors($state, \@labels)

Given a state/set of states, and one or more labels, returns a list of
the states (without duplicates) reachable from the states via a single
transition having any of the given labels. If no labels are given, returns
the states reachable by any (single) transition.

Note that this method makes no distinction for epsilon transitions, these
are only special in FLAT::NFA objects.

=item $fa-E<gt>alphabet

Returns the list of characters (without duplicates) used among all
transition labels in the automaton.

=back

=head2 Conversions To External Formats

=over

=item $fa-E<gt>as_graphviz

Returns a string containing a GraphViz (dot) description of the automaton,
suitable for rendering with your favorite GraphViz layout engine.

=item $fa-E<gt>as_summary

Returns a string containing a plaintext description of the automaton,
suitable for debugging purposes.

=back

=head2 Miscellaneous

=over

=item $fa-E<gt>clone

Returns an identical copy of $fa.

=back

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and 
Brett Estrade E<lt>estradb at gmail dot comE<gt>.

The initial version (FLAT::Legacy) by Brett Estrade was work towards an 
MS thesis at the University of Southern Mississippi.

Please visit the Wiki at http://www.0x743.com/flat

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
