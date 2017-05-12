package Decision::Markov;

#
# Copyright (c) 1998-2002 Alan Schwartz <alansz@uic.edu>. All rights 
# reserved. This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself.
#

require 5.000;
use strict;
use diagnostics;
use Carp;
use Decision::Markov::State;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();
$VERSION = "0.02";


sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->{'states'} = [];		# List of states
    $self->DiscountRate(0);
    $self->Reset;
    return $self;
}

sub AddState {
     my $self = shift;
     my $name = shift;
     my $utility = shift;
     my $state = new Decision::Markov::State($name,$utility);
     push(@{ $self->{'states'} }, $state);
     return $state;
}

sub States { @{ $_[0]->{'states'} } };
sub CurrentState { 
  my $self = shift;
  @_ ? $self->{'currentstate'} = shift : $self->{'currentstate'}
};
sub CumUtility { 
  my $self = shift;
  @_ ? $self->{'cumutility'} = shift : $self->{'cumutility'}
};
sub PatientsLeft { 
  my $self = shift;
  @_ ? $self->{'patientsleft'} = shift : $self->{'patientsleft'}
};
sub DiscountRate { 
  my $self = shift;
  @_ ? $self->{'discount'} = shift : $self->{'discount'}
};

sub AddPath {
     my $self = shift;
     my $from = shift;		# source state
     my $to = shift;		# destination state
     my $prob = shift;		# transition probability/function
     return "AddPath: From state '$from' isn't a State object" unless ref($from);
     return "AddPath: To state '$to' isn't a State object" unless ref($to);
     return $from->AddTransition($to,$prob);
}

# Check that transition probabilities for every node add up to 1.
# If the probabilities are functions of time, try calling them
# for t = 3 and make sure that works. Return undef if no good, otherwise 1.
sub Check {
  my $self = shift;
  foreach my $state ($self->States) {
    my $total = $state->SumProbs;
    return "Check: " . $state->Name . " has probabilities totalling $total, not 1"
       unless ($total == 1);
  }
  return undef;
}


sub Reset {
  my $self = shift;
  $self->CurrentState("");
  $self->CumUtility(0);
  $self->PatientsLeft(0);
  foreach my $state ($self->States) {
    $state->Reset;
  }
  $self->StartingState(@_) if @_;
}

sub StartingState {
  my $self = shift;
  my $initial_state = shift;
  my $numpatients = shift;
  return "StartingState: Initial state '$initial_state' isn't a State object"
       unless ref($initial_state);
  return "StartingState: Invalid number of patients: $numpatients"
       if ($numpatients && ($numpatients < 0));
  $self->CurrentState($initial_state); 
  if ($numpatients) {
    $self->PatientsLeft($numpatients); 
    $initial_state->NumPatients($numpatients);
  }
  return undef;
}


1;
__END__


=head1 NAME

Decision::Markov - Markov models for decision analysis

=head1 SYNOPSIS

  use Decision::Markov;
  $model = new Decision::Markov;
  $state = $model->AddState("Name",$utility);
  $error = $model->AddPath($state1,$state2,$probability);
  $error = $model->Check
  $model->Reset([$starting_state,[$number_of_patients]]);
  $error = $model->StartingState($starting_state[,$number_of_patients]);
  $model->DiscountRate($rate);
  ($utility,$cycles) = $model->EvalMC();
  $state = $model->EvalMCStep($cycle);
  ($utility,$cycles) = $model->EvalCoh();
  $patients_left = $model->EvalCohStep($cycle);
  $model->PrintCycle($FH,$cycle);
  $model->PrintMatrix($FH);


=head1 DESCRIPTION

This module provides functions used to built and evaluate Markov
models for use in decision analysis. A Markov model consists
of a set of states, each with an associated utility, and links
between states representing the probability of moving from one
node to the next. Nodes typically include links to themselves.
Utilities and probabilities may be fixed or may be functions
of the time in cycles since the model began running.

=head1 METHODS

=over 4

=item new

Create a new Markov model. 

=item AddState

Add a state to the model. The arguments are a string describing
the state and the utility of the state. The utility may be
specified either as a number or as a reference to a subroutine
that returns the utility. The subroutine will be passed the current
cycle number as an argument. Returns the new state, which
is an object of class Decision::Markov::State.

=item AddPath

Adds a path between two states. The arguments are the source state,
the destination state, and the probability of transition. 

Probability may be specified either as a number or as a reference to a 
subroutine that returns the probability. The subroutine will be passed the 
current cycle number as an argument.

AddPath returns undef if successful, error message otherwise.

=item Check

Checks all states in the model to include that the probabilities
of the paths from each state sum to 1. Returns undef if the model
checks out, error message otherwise.

=item Reset

Resets the model. Use before evaluating the model.

=item StartingState

Sets the state in which patients start when the model is evaluated.
The optional second argument sets the number of patients in 
a cohort when performing a cohort simulation.

Returns undef if successful or an error message.

=item DiscountRate

Sets the per-cycle discount rate for utility. By default, there is
no discounting. To set, for example, 3%/cycle discounting, use
$model->DiscountRate(.03);

If no discount rate is given, returns the current discount rate.

=item EvalMC

Performs a Monte Carlo simulation of a single patient through the
model, and returns that patient's cumulative utility and the
number of cycles the model ran. The patient
begins in the state set by StartingState.

=item EvalMCStep

Given the current model cycle,
evaluates a single step of the Markov
model, and returns the patient's new state. Internally continues
to track the patient's cumulative utility.

=item EvalCoh

Performs a cohort simulation of the model and returns the 
average cumulative utility of a patient in the cohort, and the number
of cycles the model ran. The 
number of patients and their initial state are set with
StartingState.

=item EvalCohStep

Evaluates a single cycle of a cohort simulation. Returns the number
of patients who will change states in the next cycle (i.e., if it
returns 0, you're at the end of the model run).

=item PrintCycle

Given a FileHandle object and the cycle, 
prints the current distribution of patients in the cohort (if
a cohort simulation is in progress) or the current state and
utility of the patient (if a Monte Carlo simulation is in progress).

=item PrintMatrix

Given a FileHandle object, prints the model in transition matrix form

=back

=head1 REFERENCES

Sonnenberg, F. A. & Beck, J. R. (1993). Markov Models in Medical
Decision Making: A Practical Guide. Med. Dec. Making, 13: 322-338.

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


sub EvalMC {
  my $self = shift;
  my $state = $self->CurrentState;
  $self->Reset($state);		# Make sure we're clean to start
  my $cycle = 0;
  while (not $state->FinalState) {
    $state = $self->EvalMCStep($cycle);
    $cycle++;
  }
  return ($self->CumUtility,$cycle);
}

sub EvalMCStep {
  my $self = shift;
  my $cycle = shift;
  die "EvalMCStep: Invalid cycle $cycle\n"
	unless ($cycle >= 0);
  my $state = $self->CurrentState;
  my $nextstate = $state->NextState($cycle);
  # This incorporates a correction of a half-cycle
  $self->CumUtility($self->CumUtility +
         ($self->_discount_utility($cycle,$state->Utility($cycle)) +
          $self->_discount_utility($cycle+1,$nextstate->Utility($cycle)))
         /2);
  $self->CurrentState($nextstate);
  return $nextstate;
}

sub _discount_utility {
  my $self = shift;
  my $cycle = shift;
  my $utility = shift;
  my $rate = $self->DiscountRate;
  return $utility unless $rate;
  return $utility * (1 - $rate)**$cycle;
}

sub EvalCoh {
  my $self = shift;
  my $cycle = 0;
  while ($self->PatientsLeft) {
    $self->PatientsLeft($self->EvalCohStep($cycle));
    $cycle++;
  } 
  return ($self->CumUtility,$cycle);
}

sub EvalCohStep {
  my $self = shift;
  my $cycle = shift;
  my $patients_left = 0;
  # Determine where everyone will go next cycle. Give them half credit
  # for where they are now.
  foreach my $state ($self->States) {
     $self->CumUtility($self->CumUtility + 
        0.5 * $state->NumPatients * 
        $self->_discount_utility($cycle,$state->Utility($cycle)));
     $state->DistributeCohort($cycle);
  }
  # Were there any changes or are we done?
  foreach my $state ($self->States) {
     $patients_left += abs($state->NewNumPatients - $state->NumPatients);
  }
  # If nobody's going to change, we're done. They've even gotten their
  # final half-credit already. Stop now.
  return 0 unless $patients_left;
  # Actually put everyone there. Give them half credit for where they
  # moved to.
  $cycle++;
  foreach my $state ($self->States) {
     $state->UpdateCohort();
     $self->CumUtility($self->CumUtility + 
                          0.5 * $state->NumPatients * 
           $self->_discount_utility($cycle,$state->Utility($cycle)));
  }
  return $patients_left;
}
   
# Try to determine whether we're in a Monte Carlo or cohort simulation
# and print a picture of the current cycle.
sub PrintCycle {
  my $self = shift;
  my $fh = shift;
  my $cycle = shift;
  my @states = $self->States;
  if ($self->PatientsLeft) {
    # This is a cohort simulation
    if ($cycle == 0) {
       # First time. Print a header
       # We want the output to look like this:
       # Cycle CumUtility  State1 State2 State3 State4 State5
       #  1      <util>      #      #      #      #      #   
       $fh->print("                           COHORT SIMULATION\n");
       my $header = "Cycle Utility";
       foreach (1 .. scalar(@states)) {
         $header .= " State$_";
       }
       $fh->print("$header\n");
    }
    $fh->printf("%-5d %7.2f", $cycle, $self->CumUtility);
    foreach (@states) {
      $fh->printf(" %6d", $_->NumPatients);
    }
    $fh->print("\n");
  } else {
    # Monte Carlo simulation
    if ($cycle == 0) {
       # First time. Set up the header
       $fh->print("                           MONTE CARLO SIMULATION\n");
       my $header = "Cycle Utility";
       foreach (1 .. scalar(@states)) {
         $header .= " State$_";
       }
       $fh->print("$header\n");
    }
    $fh->printf("%-5d %7.2f", $cycle, $self->CumUtility);
    foreach (@states) {
      if ($self->CurrentState eq $_) {
        $fh->printf(" %6s", "XXX");
      } else {
        $fh->printf(" %6s", "");
      }
    }
    $fh->print("\n");

  }
}

#  $model->PrintDiagram; ?

sub PrintMatrix {
  my $self = shift;
  my $fh = shift;
  my $codes = '123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  my @codes = split(//,$codes);
  my @states = $self->States;
  # State key
  $fh->printf("%-5s %-50s %10s\n","State","Description","Utility");
  foreach (0..$#states) {
    my $utility = $states[$_]->Utility;
    $utility = "Fcn" if ref($utility);
    $fh->printf("%s%-4s %-50s %10f\n",
                $states[$_]->FinalState ? "*" : " ", $codes[$_],
                $states[$_]->Name, $states[$_]->Utility);
  }
  $fh->print("\n\n* = Absorbing state (no transitions from this state)\n\n");
  $fh->print("Discount rate for utilities: ",$self->DiscountRate,"\n\n");
  $fh->print("Transition Probability Matrix\n\n");
  # Prob matrix
  $fh->print("     ");
  foreach (0..$#states) {
    $fh->printf(" %5s",$codes[$_]);
  }
  $fh->print("\n");
  foreach my $r (0..$#states) {
    $fh->printf("%-5s",$codes[$r]);
    foreach my $c (0..$#states) {
      my $prob;
      if (defined($prob = $states[$r]->TransitionProb($states[$c]))) {
        $fh->printf(" %5.3f",$prob);
      } else {
        $fh->printf(" %5s","");
      }
    }
    $fh->print("\n");
  }
}
