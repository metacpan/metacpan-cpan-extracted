package FLAT::PFA;
use strict;
use base 'FLAT::NFA';
use Carp;

use FLAT::Transition;

use constant LAMBDA => '#lambda';

# Note: in a PFA, states are made up of active nodes.  In this implementation, we have
# decided to retain the functionality of the state functions in FA.pm, although the entities
# being manipulated are technically nodes, not states.  States are only explicitly tracked
# once the PFA is serialized into an NFA.  Therefore, the TRANS member of the PFA object is
# the nodal transition function, gamma.  The state transition function, delta, is not used
# in anyway, but is derived out of the PFA->NFA conversion process.


# The new way of doing things eliminated from PFA.pm of FLAT::Legacy is the 
# need to explicitly track: start nodes, final nodes, symbols, and lambda & epsilon symbols,  

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_); # <-- SUPER is FLAT::NFA
    return $self;
}

# Singleton is no different than the NFA singleton
sub singleton {
    my ($class, $char) = @_;
    my $pfa = $class->new;
    if (not defined $char) {
        $pfa->add_states(1);
        $pfa->set_starting(0);
    } elsif ($char eq "") {
        $pfa->add_states(1);
        $pfa->set_starting(0);
        $pfa->set_accepting(0);
    } else {
        $pfa->add_states(2);
        $pfa->set_starting(0);
        $pfa->set_accepting(1);
        $pfa->set_transition(0, 1, $char);
    }
    return $pfa;
}

# attack of the clones
sub as_pfa { $_[0]->clone() }

sub set_starting {
    my ($self, @states) = @_;
    $self->_assert_states(@states);
    $self->{STATES}[$_]{starting} = 1 for @states;
}

# Creates a single start state with epsilon transitions from
# the former start states;
# Creates a single final state with epsilon transitions from
# the former accepting states
sub pinch {
 my $self = shift;
 my $symbol = shift;
 my @starting = $self->get_starting;
 if (@starting > 1) {
   my $newstart = $self->add_states(1);
   map {$self->add_transition($newstart,$_,$symbol)} @starting;
   $self->unset_starting(@starting);
   $self->set_starting($newstart);
 }
 #
 my @accepting = $self->get_accepting;
 if (@accepting > 1) {
   my $newfinal = $self->add_states(1);
   map {$self->add_transition($_,$newfinal,$symbol)} @accepting;
   $self->unset_accepting(@accepting);
   $self->set_accepting($newfinal);
 }
 return;
}

# Implement the joining of two PFAs with lambda transitions
# Note: using epsilon pinches for simplicity
sub shuffle {
    my @pfas = map { $_->as_pfa } @_;
    my $result = $pfas[0]->clone;
    $result->_swallow($_) for @pfas[1 .. $#pfas];
    $result->pinch(LAMBDA);
    $result;
}

##############

sub is_tied {
    my ($self, $state) = @_;
    $self->_assert_states($state);
    return $self->{STATES}[$state]{tied};
}

sub set_tied {
    my ($self, @states) = @_;
    $self->_assert_states(@states);
    $self->{STATES}[$_]{tied} = 1 for @states;
}

sub unset_tied {
    my ($self, @states) = @_;
    $self->_assert_states(@states);
    $self->{STATES}[$_]{tied} = 0 for @states;
}

sub get_tied {
    my $self = shift;
    return grep { $self->is_tied($_) } $self->get_states;
}

##############

# joins two PFAs in a union (or) - no change from NFA
sub union {
    my @pfas = map { $_->as_pfa } @_;    
    my $result = $pfas[0]->clone;    
    $result->_swallow($_) for @pfas[1 .. $#pfas];
    $result->pinch('');
    $result;
}

# joins two PFAs via concatenation  - no change from NFA
sub concat {
    my @pfas = map { $_->as_pfa } @_;
    
    my $result = $pfas[0]->clone;
    my @newstate = ([ $result->get_states ]);
    my @start = $result->get_starting;

    for (1 .. $#pfas) {
        push @newstate, [ $result->_swallow( $pfas[$_] ) ];
    }

    $result->unset_accepting($result->get_states);
    $result->unset_starting($result->get_states);
    $result->set_starting(@start);
    
    for my $pfa_id (1 .. $#pfas) {
        for my $s1 ($pfas[$pfa_id-1]->get_accepting) {
        for my $s2 ($pfas[$pfa_id]->get_starting) {
            $result->set_transition(
                $newstate[$pfa_id-1][$s1],
                $newstate[$pfa_id][$s2], "" );
        }}
    }

    $result->set_accepting(
        @{$newstate[-1]}[ $pfas[-1]->get_accepting ] );

    $result;
}

# forms closure around a the given PFA  - no change from NFA
sub kleene {
    my $result = $_[0]->clone;
    
    my ($newstart, $newfinal) = $result->add_states(2);
    
    $result->set_transition($newstart, $_, "")
        for $result->get_starting;
    $result->unset_starting( $result->get_starting );
    $result->set_starting($newstart);

    $result->set_transition($_, $newfinal, "")
        for $result->get_accepting;
    $result->unset_accepting( $result->get_accepting );
    $result->set_accepting($newfinal);

    $result->set_transition($newstart, $newfinal, "");    
    $result->set_transition($newfinal, $newstart, "");
    
    $result;
}

sub as_nfa { 
    my $self = shift;
    my $result = FLAT::NFA->new();    
    # Dstates is initially populated with the start state, which 
    # is exactly the set of all nodes marked as a starting node
    my @Dstates = [sort($self->get_starting())]; # I suppose all start states are considered 'tied'
    my %DONE = ();                               # |- what about all accepting states? I think so...
    # the main while loop that ends when @Dstates becomes exhausted
    my %NEW = ();
    while (@Dstates) {
      my $current = pop(@Dstates);
      my $currentid = join(',',@{$current});
      $DONE{$currentid}++;    # mark done
      foreach my $symbol ($self->alphabet(),'') {  # Sigma UNION epsilon
        if (LAMBDA eq $symbol) {
          my @NEXT = ();  
	  my @tmp = $self->successors([@{$current}],$symbol);
	  if (@tmp) {
	    my @pred = $self->predecessors([@tmp],LAMBDA);
            if ($self->array_is_subset([@pred],[@{$current}])) {
              push(@NEXT,@tmp,$self->array_complement([@{$current}],[@pred]));
              @NEXT = sort($self->array_unique(@NEXT));
	      my $nextid = join(',',@NEXT);
	      push(@Dstates,[@NEXT]) if (!exists($DONE{$nextid})); 	            
              # make new states if none exist and track
              if (!exists($NEW{$currentid})) {$NEW{$currentid} = $result->add_states(1)};
              if (!exists($NEW{$nextid}))    {$NEW{$nextid} = $result->add_states(1)   };
	      $result->add_transition($NEW{$currentid},$NEW{$nextid},'');  
            }
	  }
        } else {
	  foreach my $node (@{$current}) {
	    my @tmp = $self->successors([$node],$symbol);	    
	    foreach my $new (@tmp) {
              my @NEXT = ();	      
              push(@NEXT,$new,$self->array_complement([@{$current}],[$node]));
              @NEXT = sort($self->array_unique(@NEXT));
	      my $nextid = join(',',@NEXT);
	      push(@Dstates,[@NEXT]) if (!exists($DONE{$nextid})); 	            
              # make new states if none exist and track
              if (!exists($NEW{$currentid})) {$NEW{$currentid} = $result->add_states(1)};
              if (!exists($NEW{$nextid}))    {$NEW{$nextid} = $result->add_states(1)   };
	      $result->add_transition($NEW{$currentid},$NEW{$nextid},$symbol);	  
	    }
	  }
	}
      }
    }
    $result->set_starting($NEW{join(",",sort $self->get_starting())});
    $result->set_accepting($NEW{join(",",sort $self->get_accepting())});
    return $result;
 }

1;

__END__

=head1 NAME

FLAT::PFA - Parallel finite automata

=head1 SYNOPSIS

A FLAT::PFA object is a finite automata whose transitions are labeled either 
with characters, the empty string (epsilon), or a concurrent line of execution 
(lambda).  It essentially models two FSA in a non-deterministic way such that 
a string is valid it puts the FSA of the shuffled languages both into a final, 
or accepting, state.  A PFA is an NFA, and as such exactly describes a regular 
language.

A PFA contains nodes and states.  A state is made up of whatever nodes happen 
to be active.  There are two transition functions, nodal transitions and state 
transitions.  When a PFA is converted into a NFA, there is no longer a need for 
nodes or nodal transitions, so they go are eliminated.  PFA model state spaces 
much more compactly than NFA, and an N state PFA may represent 2**N non-deterministic 
states. This also means that a PFA may represent up to 2^(2^N) deterministic states.

=head1 USAGE

(not implemented yet)

In addition to implementing the interface specified in L<FLAT> and L<FLAT::NFA>, 
FLAT::PFA objects provide the following PFA-specific methods:

=over

=item $pfa-E<gt>shuffle

Shuffle construct for building a PFA out of a PRE (i.e., a regular expression with
the shuffle operator)

=item $pfa-E<gt>as_nfa

Converts a PFA to an NFA by enumerating all states; similar to the Subset Construction
Algorithm, it does not implement e-closure.  Instead it treats epsilon transitions
normally, and joins any states resulting from a lambda (concurrent) transition
using an epsilon transition.

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
