package Decision::Markov::State;

require 5.000;
use strict;
use diagnostics;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();
$VERSION = do { my @r = (q$ProjectVersion: 0.4 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $name = shift;
    my $utility = shift;
    my $self = {};
    bless $self, $class;
    $self->Name($name);			# State name
    $self->{'utility'} = $utility;	# State utility
    $self->{'transitions'} = {};	# Transitions to other nodes
    $self->Reset();			# Reset simulation parameters
    return $self;
}


sub Reset {
    my $self = shift;
    $self->NumPatients(0);
    $self->NewNumPatients(0);
}

sub Name { 
  my $self = shift;
  @_ ? $self->{'name'} = shift : $self->{'name'};
}
sub NumPatients { 
  my $self = shift;
  @_ ? $self->{'numpatients'} = shift : $self->{'numpatients'};
}
sub NewNumPatients { 
  my $self = shift;
  @_ ? $self->{'newnumpatients'} = shift : $self->{'newnumpatients'};
}
sub Transitions { %{ $_[0]->{'transitions'} } }
sub Utility {
  my $self = shift;
  my $cycle = shift;
  my $utility = $self->{'utility'};
  $utility = &$utility($cycle) if (ref($utility));
  return $utility;
}

sub AddTransition {
  my $self = shift;
  my $to = shift;
  my $prob = shift;
  return "AddTransition: There's already a transition from " . $self->Name . " to " . $to->Name if defined($self->{'transitions'}->{$to->Name}); 
  $self->{'transitions'}->{$to->Name} = [ $to, $prob ];
  return undef;
}

sub TransitionProb {
  my $self = shift;
  my $to = shift;
  my $cycle = shift;
  my %transitions = $self->Transitions;
  return 0 unless $transitions{$to->Name};
  my $prob = $transitions{$to->Name}[1];
  return $prob unless (ref($prob) and defined($cycle));
  return &$prob($cycle);
}

sub SumProbs {
  my $self = shift;
  my $cycle = shift;
  $cycle = 3 unless defined($cycle);
  my $sum = 0;
  my %transitions = $self->Transitions;
  foreach my $listref (values %transitions) {
    my $prob = ${ $listref }[1];
    $prob = &$prob($cycle) if (ref($prob));
    $sum += $prob;
  }
  return $sum;
}

# Are we in a final state? A final state is a state that has only
# one transition path, leading back to the state itself.
sub FinalState {
  my $self = shift;
  my %transitions = $self->Transitions;
  my @transition_states = keys %transitions;
  # Not a final state if there are multiple transitions
  return 0 if (scalar(@transition_states) > 1);
  # Not a final state if the transition is to a different state
  return 0 if $transitions{$transition_states[0]}->[0] ne $self;
  return 1;
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Decision::Markov::State - Markov state object for Decision::Markov

=head1 SYNOPSIS

  use Decision::Markov::State;
  $state = new Decision::Markov::State("Name",<utility>);
  $state->Reset();
  $state->Name("Name");
  $name = $state->Name;
  $state->NumPatients(100);
  $num = $state->NumPatients;
  $utility = $state->Utility($cycle);
  $error = $state->AddTransition($newstate,$prob);
  $prob = $state->TransitionProb($newstate[,$cycle]);
  $total = $state->SumProbs([$cycle]);
  $boolean = $state->FinalState;
  $newstate = $state->NextState($cycle);
  $state->DistributeCohort($cycle);
  $state->UpdateCohort();

=head1 DESCRIPTION

This module implements a Markov state object used by Decision::Markov.
It's not really intended to be used directly, but for completeness,
its public methods are documented here.

=head1 METHODS

=over 4

=item new

Creates a new Markov state object, given a name for the state and its
utility. The utility may be specified either as a number or as a
reference to a subroutine which will be called with the current model
cycle as its only argument.

=item Reset

Resets the state, clearing temporary information that is stored in the
state during model evaluations.

=item Name

With no argument, returns the name of the state. With an argument, sets
the name of the state.

=item NumPatients

With no argument, returns the number of patients in the state. With an
argument, sets the number of patients in the state.

=item Utility

Given the current model cycle, computes and returns the utility of
being in the state during that cycle.

=item AddTransition

Given a second Markov state, and a transition probability, adds a
transition from the first state to the second that will occur with
probability equal to the transition probability at the model
cycle. Probability can be specified as a number or a reference to a
subroutine which will be called with the current model cycle as its
only argument.

Returns undef if successful or an error message if unsuccessful
(e.g., there's already a transition between those states.)

=item TransitionProb

Given a second Markov state, return the probability of transitioning
from the first state to the second. May return either a number or a
reference to a subroutine that can be called with the current model
cycle to get the numerical probability. If TransitionProb is given a
cycle number as its optional second argument, it will always return
the probability during that cycle. If a state doesn't have a
transition to the new state, this function returns 0.

=item SumProbs

Return the sum of all the transition probabilities from the state.  If
any of the probabilities are subroutine references, they are evaluated
at the cycle given as an argument to SumProbs or at cycle 3 if
SumProbs is called without arguments. This function is used to check
that probabilities sum to 1.

=item FinalState

Returns 1 if the state is a final state: a state with no transitions
to states other than itself. Otherwise, returns 0.

=item NextState

Given the model cycle, randomly determine and return the next state
that a patient in this state will move to, based on the transition
probabilities. Used in Monte Carlo evaluations.

=item DistributeCohort

Given the model cycle, distribute all of the patients in the state to
other states in proportion to their transition probabilities. Note
that a state usually transitions to itself as well, so some of the
patients are distributed back to the same state. Distributed patients
are held in a temporary attribute of the object so that all states can
be distributed before calling UpdateCohort to actually set the new
number of patients for each state. Used in cohort simulations.

=item UpdateCohort

Update the number of patients in this state from the temporary
attribute created by DistributeCohort.

=back

=head1 COPYRIGHT

Copyright (c) 1998 Alan Schwartz <alansz@uic.edu>. All rights reserved. 
This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=head1 REVISION HISTORY

=over 8

=item 0.01

March 1988 - Initial concept.

=back

=cut

# Autoload methods

# In a Monte Carlo simulation, draw a suitable next state based
# on the transition probabilities, and return it.
sub NextState {
  my $self = shift;
  my $cycle = shift;
  my %transitions = $self->Transitions;
  my $random = rand;  # Includes 0, excludes 1
  my $totalprob = 0;
  foreach my $listref (values %transitions) {
    my ($state,$prob) = @{ $listref };
    $prob = &$prob($cycle) if (ref($prob));
    $totalprob += $prob;
    return $state if ($random < $totalprob);
  }
  # Should never reach this point.
  die "NextState(" . $self->Name . ",$cycle): totalprob = $totalprob, random = $random\n";
}

# Distribute the number of patients in the state to newnumpatients
# in transition states
sub DistributeCohort {
  my $self = shift;
  my $cycle = shift;
  my $patients = $self->NumPatients;
  my %transitions = $self->Transitions;
  foreach my $listref (values %transitions) {
    my ($state,$proportion) = @{ $listref };
    $proportion = &$proportion($cycle) if (ref($proportion));
    $state->NewNumPatients($state->NewNumPatients +
        sprintf("%.0f",$self->NumPatients * $proportion));
  }
} 

# Update the state's numpatients from newnumpatients
sub UpdateCohort {
  my $self = shift;
  $self->NumPatients($self->NewNumPatients);
  $self->NewNumPatients(0);
}
