# $Revision: 1.4 $ $Date: 2006/03/02 21:00:28 $ $Author: estrabd $

package FLAT::Legacy::FA::NFA;

use base 'FLAT::Legacy::FA';
use strict;
use Carp;

use FLAT::Legacy::FA::DFA;
use Data::Dumper;

sub new {
  my $class = shift;
  bless {
    _START_STATE => undef,  # start states -> only 1!
    _STATES => [],          # Set of all states
    _FINAL_STATES => [],    # Set of final states, subset of _STATES
    _SYMBOLS => [],         # Symbols
    _TRANSITIONS => {},     # Transition table
    _EPSILON => 'epsilon',  # how an epsilon transition is represented
  }, $class;
}

sub jump_start {
  my $self = shift;
  my $NFA = FLAT::Legacy::FA::NFA->new();
  my $symbol = shift;
  if (!defined($symbol)) {
    $symbol = $NFA->get_epsilon_symbol();
  } else {
    chomp($symbol);
  }
  my $newstart = crypt(rand 8,join('',[rand 8, rand 8]));
  my $newfinal = crypt(rand 8,join('',[rand 8, rand 8]));  
  # add states
  $NFA->add_state($newstart,$newfinal);
  # add symbol
  $NFA->add_symbol($symbol);
  # set start and final
  $NFA->set_start($newstart);
  $NFA->add_final($newfinal);
  # add single transition
  $NFA->add_transition($newstart,$symbol,$newfinal);
  #return $NFA
  return $NFA;
}

sub load_file {
  my $self = shift;
  my $file = shift;
  if (-e $file) {
    open (NFA,"<$file");
    my $string = undef;
    while (<NFA>) {
      $string .= $_;
    }
    close (NFA);
    $self->load_string($string);
  }
}

sub load_string {
  my $self = shift;
  my $string = shift;
  my @lines = split("\n",$string);
  my $CURR_STATE = undef;
  foreach (@lines) {
    # strip comments
    $_ =~ s/\s*#.*$//;
    # check if line is a state, transition, or keyword
    if (m/^\s*([\w\d]*)\s*:\s*$/) {
      #print STDERR "Found transitions for state $1\n";
      $self->add_state($1);
      $CURR_STATE = $1;
    } elsif (m/^\s*([\w\d]*)\s*([\w\d,]*)\s*$/ && ! m/^$/) {
      # treat as transition
      #print STDERR "Input: '$1' goes to $2\n";
      my @s = split(',',$2);
      $self->add_transition($CURR_STATE,$1,@s);
      $self->add_symbol($1);
    } elsif (m/^\s*([\w\d]*)\s*::\s*([\w\d,]*)\s*$/ && ! m/^$/) {
      # Check for known header keywords
      my $val = $2;
      if ($1 =~ m/START/i) {
        $self->set_start($val);
      } elsif ($1 =~ m/FINAL/i) {
        my @s = split(',',$val);
	$self->add_final(@s);
      } elsif ($1 =~ m/EPSILON/i) {
        $self->set_epsilon($val);
      } else {
        print STDERR "WARNING: $1 is not a valid header...\n";
      }
    }
  }  
}

sub clone {
  my $self = shift;
  my $NFA = FLAT::Legacy::FA::NFA->new();
  $NFA->add_state($self->get_states());
  $NFA->add_final($self->get_final());
  $NFA->add_symbol($self->get_symbols());
  $NFA->set_start($self->get_start());
  $NFA->set_epsilon($self->get_epsilon_symbol);
  foreach my $state ($self->get_states()) {
    foreach my $symbol (keys %{$self->{_TRANSITIONS}{$state}}) {
      $NFA->add_transition($state,$symbol,@{$self->{_TRANSITIONS}{$state}{$symbol}});
    }
  }
  return $NFA;
}

sub append_nfa {
  my $self = shift;
  my $NFA = shift;
  # clone $NFA
  my $NFA1 = $NFA->clone();
  # pinch off self - ensures a single final state
  $self->pinch();
  # pinch off $NFA1 to ensure a single final state
  $NFA1->pinch();
  # ensure unique state names
  $self->ensure_unique_states($NFA1,crypt(rand 8,join('',[rand 8, rand 8])));
  # sychronize epsilon symbol
  if ($NFA1->get_epsilon_symbol() ne $self->get_epsilon_symbol()) {
    $NFA1->rename_symbol($NFA1->get_epsilon_symbol(),$self->get_epsilon_symbol());  
  }  
  # add new states from NFA1
  foreach my $state ($NFA1->get_states()) {
    $self->add_state($state);
  };
  # add new symbols from NFA1
  foreach my $symbol ($NFA1->get_symbols()) { 
    $self->add_symbol($symbol);
  }
  # add transitions from NFA1
  foreach my $state (keys %{$NFA1->{_TRANSITIONS}}) {
    foreach my $symbol (keys %{$NFA1->{_TRANSITIONS}{$state}}) {
      $self->add_transition($state,$symbol,@{$NFA1->{_TRANSITIONS}{$state}{$symbol}});
    }
  }
  # remove current final state and saves it for future reference
  my $oldfinal = pop(@{$self->{_FINAL_STATES}});
  # add new epsilon transition from the old final state of $self to the start state of NFA1
  $self->add_transition($oldfinal,$self->get_epsilon_symbol(),$NFA1->get_start());
  # mark the final state of NFA1 as the final state of $self
  $self->add_final($NFA1->get_final());
  # states not renumbered - can done explicity by user
  return;
}

sub prepend_nfa {
  my $self = shift;
  my $NFA = shift;
  # clone $NFA
  my $NFA1 = $NFA->clone();
  # pinch off self - ensures a single final state
  # pinch off self - ensures a single final state
  $self->pinch();
  # pinch off $NFA1 to ensure a single final state
  $NFA1->pinch();
  # ensure unique state names
  $self->ensure_unique_states($NFA1,crypt(rand 8,join('',[rand 8, rand 8])));
  # sychronize epsilon symbol
  if ($NFA1->get_epsilon_symbol() ne $self->get_epsilon_symbol()) {
    $NFA1->rename_symbol($NFA1->get_epsilon_symbol(),$self->get_epsilon_symbol());  
  }  
  # add new states from NFA1
  foreach my $state ($NFA1->get_states()) {
    $self->add_state($state);
  };
  # add new symbols from NFA1
  foreach my $symbol ($NFA1->get_symbols()) { 
    $self->add_symbol($symbol);
  }
  # add transitions from NFA1
  foreach my $state (keys %{$NFA1->{_TRANSITIONS}}) {
    foreach my $symbol (keys %{$NFA1->{_TRANSITIONS}{$state}}) {
      $self->add_transition($state,$symbol,@{$NFA1->{_TRANSITIONS}{$state}{$symbol}});
    }
  }
  # remove current final state of $NFA1 and saves it for future reference
  my $oldfinal = pop(@{$NFA1->{_FINAL_STATES}});
  # add new epsilon transition from the old final state of $NFA1 to the start state of $self
  $self->add_transition($oldfinal,$self->get_epsilon_symbol(),$self->get_start());
  # mark the final state of NFA1 as the final state of $self
  $self->set_start($NFA1->get_start());
  # states not renumbered - can done explicity by user
  return;
}

sub or_nfa {
  my $self = shift;
  my $NFA1 = shift;
  # pinch off self - ensures a single final state
  $self->pinch();
  # pinch off $NFA1 to ensure a single final state
  $NFA1->pinch();
  # ensure unique state names
  $self->ensure_unique_states($NFA1,crypt(rand 8,join('',[rand 8, rand 8])));
  # sychronize epsilon symbol
  if ($NFA1->get_epsilon_symbol() ne $self->get_epsilon_symbol()) {
    $NFA1->rename_symbol($NFA1->get_epsilon_symbol(),$self->get_epsilon_symbol());  
  }  
  # add new states from NFA1
  foreach my $state ($NFA1->get_states()) {
    $self->add_state($state);
  };
  # add new symbols from NFA1
  foreach my $symbol ($NFA1->get_symbols()) { 
    $self->add_symbol($symbol);
  }
  # add transitions from NFA1
  foreach my $state (keys %{$NFA1->{_TRANSITIONS}}) {
    foreach my $symbol (keys %{$NFA1->{_TRANSITIONS}{$state}}) {
      $self->add_transition($state,$symbol,@{$NFA1->{_TRANSITIONS}{$state}{$symbol}});
    }
  }
  # save old start states
  my $start1 = $self->get_start();
  my $start2 = $NFA1->get_start();
  # create new start state
  my $newstart = crypt(rand 8,join('',[rand 8, rand 8]));
  $self->add_state($newstart);
  # set this new state as the start
  $self->set_start($newstart);
  # add the final state from NFA1 
  $self->add_final($NFA1->get_final());
  # create transitions to old start states from new start state
  $self->add_transition($newstart,$self->get_epsilon_symbol(),$start1);
  $self->add_transition($newstart,$self->get_epsilon_symbol(),$start2);
  # the result is not pinched, but it is in PFA->or_pfa because the epsilon
  # transition is required to convert a PFA properly to an NFA...a similar
  # restriction may occur here...in this case, uncomment the following line
  #$self->pinch();
  return;
}

sub kleene {
  my $self = shift;
  my $newstart = crypt(rand 8,join('',[rand 8, rand 8]));
  my $newfinal = crypt(rand 8,join('',[rand 8, rand 8]));  
  # pinch off self - ensures a single final state
  $self->pinch();
  my $oldstart = $self->get_start();
  my $oldfinal = pop(@{$self->{_FINAL_STATES}});
  # add new states
  $self->add_state($newstart,$newfinal);
  # set start
  $self->set_start($newstart);
  # set final
  $self->add_final($newfinal);
  # $oldfinal->$oldstart
  $self->add_transition($oldfinal,$self->get_epsilon_symbol(),$oldstart);  
  # $newstart->$oldstart
  $self->add_transition($newstart,$self->get_epsilon_symbol(),$oldstart);
  # $oldfinal->$newstart
  $self->add_transition($oldfinal,$self->get_epsilon_symbol(),$newfinal);
  # $newstart->$newfinal
  $self->add_transition($newstart,$self->get_epsilon_symbol(),$newfinal);  
  return;
}

sub pinch {
  my $self = shift;
  # do only if there is more than one final state
  my $newfinal = join(',',@{$self->{_FINAL_STATES}});
  $self->add_state($newfinal);
  while (@{$self->{_FINAL_STATES}}) {
    # design decision - remove all final states so that the common
    # one is the only final state and all former final states have an
    # epsilon transition to it - could prove costly for NFA->to_dfa, so
    # this could change
    my $state = pop(@{$self->{_FINAL_STATES}});
    # add new transition unless it is to the final state itself
    if ($state ne $newfinal) {
      $self->add_transition($state,$self->get_epsilon_symbol(),$newfinal)
    }
  }
  $self->add_final($newfinal);
  # FA->number_states() could be used here, but the user may not
  # want the states renamed, so it can be used explicitly
  return;
}

sub reverse {
  my $self = shift;
  # pinch
  $self->pinch();
  # make a distinct copy of self
  my $NFA1 = $self->clone();
  # reset out $self->{_TRANSITIONS}
  $self->{_TRANSITIONS} = {};
  # swap start and final states
  my $start = $self->get_start();
  $self->set_start(pop(@{$self->{_FINAL_STATES}}));
  $self->add_final($start);
  # cycle through transitions and reverse arcs
  foreach my $state (keys %{$NFA1->{_TRANSITIONS}}) {
    foreach my $symbol (keys %{$NFA1->{_TRANSITIONS}{$state}}) {
      foreach my $destination (@{$NFA1->{_TRANSITIONS}{$state}{$symbol}}) {
        $self->add_transition($destination,$symbol,$state);
      }
    }
  }
  return;
}

sub rename_state {
  my $self = shift;
  my $oldname = shift;
  my $newname = shift;
  # make sure $oldname is an actual state in this FA
  if (!$self->is_state($newname)) {
    if ($self->is_state($oldname)) {
      # replace name in _STATES array
      my $i = 0;
      foreach ($self->get_states()) {
	if ($_ eq $oldname) {
          $self->{_STATES}[$i] = $newname; 
       	  last;
	}
	$i++;
      }
      # replace name if start state
      if ($self->is_start($oldname)) {
        $self->set_start($newname);
      }
      # replace transitions
      foreach my $state (keys %{$self->{_TRANSITIONS}}) {
	foreach my $symbol (keys %{$self->{_TRANSITIONS}{$state}}) {
	  my $j = 0;
          foreach my $next (@{$self->{_TRANSITIONS}{$state}{$symbol}}) {
            # rename destination states
	    if ($self->{_TRANSITIONS}{$state}{$symbol}[$j] eq $oldname) {
	      $self->{_TRANSITIONS}{$state}{$symbol}[$j] = $newname;
	    }
            $j++;
	  }
	  # rename start state
	  if ($state eq $oldname) {
   	    $self->add_transition($newname,$symbol,@{$self->{_TRANSITIONS}{$state}{$symbol}});  
	  }
	}	
        if ($state eq $oldname) {
  	  # delete all transitions of old state
	  delete($self->{_TRANSITIONS}{$state});
	}
      }
      # replace final states
      $i = 0;
      foreach ($self->get_final()) {
	if ($_ eq $oldname) {
          $self->{_FINAL_STATES}[$i] = $newname; 
	}
	$i++;
      }
      #      
    } else {
      print STDERR "Warning: $oldname is not a current state\n";
    }
  } else {
    print STDERR "Warning: $newname is a current state\n";  
  }
  return;
}

# renames symbol
sub rename_symbol {
  my $self = shift;
  my $oldsymbol = shift;
  my $newsymbol = shift;
  # make sure $oldsymbol is a symbol and do not bother if
  # $newsymbol ne $oldsymbol
  if ($self->is_symbol($oldsymbol) && $newsymbol ne $oldsymbol) {
    # change in $self->{_SYMBOLS}
    my $i = 0;
    foreach ($self->get_symbols()) {
      if ($_ eq $oldsymbol) {
	$self->{_SYMBOLS}[$i] = $newsymbol;
	last;
      }
      $i++;
    }
    # change in $self->{_TRANSITIONS}
    # replace transition symbols
    foreach my $state (keys %{$self->{_TRANSITIONS}}) {
      foreach my $symbol (keys %{$self->{_TRANSITIONS}{$state}}) {
        if ($symbol eq $oldsymbol) {
	  $self->add_transition($state,$newsymbol,@{$self->{_TRANSITIONS}{$state}{$symbol}});
	  delete($self->{_TRANSITIONS}{$state}{$symbol});
	}
      }	
    }
    # also look at $self->{_EPSILON}
    if ($self->get_epsilon_symbol() eq $oldsymbol) {
      $self->set_epsilon($newsymbol);
    }         
  }
  return;
}

sub add_transition {
  my $self = shift;
  my $state = shift;
  my $symbol = shift;
  # adds state if not already added
  $self->add_state($state);
  # adds symbol if not already added
  $self->add_symbol($symbol);
  foreach my $next (@_) {
    if (!$self->is_member($next,@{$self->{_TRANSITIONS}{$state}{$symbol}})) {
      push (@{$self->{_TRANSITIONS}{$state}{$symbol}},$next);
    }
  }
  return;
}

sub get_transition_on {
  my $self = shift;
  my $state = shift;
  my $symbol = shift;
  my @ret = undef;
  if ($self->is_state($state) && $self->is_symbol($symbol)) {  
    if (defined($self->{_TRANSITIONS}{$state}{$symbol})) {
      @ret = @{$self->{_TRANSITIONS}{$state}{$symbol}};
    }
  }
  return @ret;  
}

sub set_epsilon {
  my $self = shift;
  my $epsilon = shift;
  $self->{_EPSILON} = $epsilon;
  return;
}

sub get_epsilon_symbol {
  my $self = shift;
  return $self->{_EPSILON};
}

sub get_epsilon_transitions {
  my $self = shift;
  my $state = shift;
  my @ret = ();
  if ($self->is_state($state)) {
    if (defined($self->{_TRANSITIONS}{$state}{$self->get_epsilon_symbol()})) {
      @ret = @{$self->{_TRANSITIONS}{$state}{$self->get_epsilon_symbol()}};
    }
  }
  return @ret;  
}

sub delete_epsilon {
  my $self = shift;
  delete($self->{_EPSILON});
  return;
}

sub to_dfa {
  my $self = shift;
  my @Dstates = (); # stack of new states to find transitions for 
  # New DFA object reference
  my $DFA = FLAT::Legacy::FA::DFA->new();
  # Initialize DFA start state by performing e-closure on the NFA start state
  my @Start = $self->epsilon_closure($self->get_start());
  # Add this state to Dstates - subsets stored as anonymous arrays (no faking here!)
  push(@Dstates,[sort(@Start)]);
  # Serialize subset into new state name - i.e, generate string-ified name
  my $ns = join('_',@Start);
  # Add start state to DFA (placeholder Dtran not used)
  $DFA->set_start($ns);
  # Add new state (serialized name) to DFA state array
  $DFA->add_state($ns);
  # Check if start state is also final state, if so add
  foreach my $s (@Start) {
    if ($self->is_final($s) && !$DFA->is_final($ns)) {
      $DFA->add_final($ns);
    }
  }
  # Loop until Dstate stack is exhausted
  while (@Dstates) {
    # pop next state off to check
    my @T = @{pop @Dstates};
    # Serialize subset into a string name
    my $CURR_STATE = join('_',@T);
    # loop over each input symbol
    foreach my $symbol ($self->get_symbols()) {
      # Obviously do not add the epsilon symbol to the dfa
      if ($symbol ne $self->get_epsilon_symbol()) {
	# Add symbol - add_symbol ensures set of symbols is unique
	$DFA->add_symbol($symbol);
	# Get new subset of transition states
	my @new = $self->epsilon_closure($self->move($symbol,(@T)));
	# Serialize name of new state
	$ns = join('_',@new);
	# Add transition as long as $ns is not empty string
	if ($ns !~ m/^$/) {
          $DFA->add_transition($CURR_STATE,$symbol,$ns);
	  # Do only if this is a new state and it is not an empty string
	  if (!$DFA->is_state($ns)) {
            # add subset to @Dstates as an anonymous array
            push(@Dstates,[@new]);
            $DFA->add_state($ns);
            # check to see if any NFA final states are in
	    # the new DFA states
	    foreach my $s (@new) {
	      if ($self->is_final($s) && !$DFA->is_final($ns)) {
		$DFA->add_final($ns);
	      }
	    }	  
	  }
	}
      }
    }
  }
  return $DFA;
}

sub move {
  my $self = shift;
  my $symbol = shift;
  my @subset = @_; # could be one state, could be a sub set of states...
  my @T = ();
  # Loop over subset until exhausted
  while (@subset) {
    # get a state from the subset
    my $state = pop @subset;
    # get all transitions for $t, and put the in @u
    my @u = $self->get_transition_on($state,$symbol);
    foreach (@u) {
      if (defined($_)) {
        # Add to new subset if not there already
	if (!$self->is_member($_,@T)) {
          push(@T,$_);
	}
      }
    }
  }
  # Returns ref to sorted subset array instead of list to preserve subset
  return sort(@T); 
}

sub epsilon_closure {
  my $self = shift;
  my @subset = @_; # could be one state, could be a sub set of states...
  # initialize @closure with provided sub set
  my @closure = @subset;
  # loop over subset until exhausted
  while (@subset) {
    # get a state from the subset
    my $state = pop @subset;
    # get all epsilon transitions for $state, and put the in @u
    my @u = $self->get_epsilon_transitions($state);
    # Loop over subset
    foreach (@u) {
      if (defined($_)) {
	if (!$self->is_member($_,@closure)) {
          push(@closure,$_);
	  # Add state to states that must be checked for e-closure
	  push(@subset,$_);
	}
      }
    }
  }
  # Returns ref to sorted subset array instead of list to preserve subset
  return sort(@closure); 
}

sub info {
  my $self = shift;
  my $out = ''; 
  $out .= sprintf ("States         : ");
  foreach ($self->get_states()) {
    $out .= sprintf "'$_' ";
  }
  $out .= sprintf ("\nStart State    : '%s'\n",$self->get_start());
  $out .= sprintf ("Final State(s) : ");
  foreach ($self->get_final()) {
    $out .= sprintf "'$_' ";
  }
  $out .= sprintf ("\nAlphabet       : ");
  foreach ($self->get_symbols()) {
    $out .= sprintf "'$_' ";
  }
  if (defined($self->get_epsilon_symbol())) {
    $out .= sprintf("\nEPSILON Symbol : '%s'",$self->get_epsilon_symbol());
  }  
  $out .= sprintf ("\nTransitions    :\n");
  foreach my $state ($self->get_states()) {
    foreach my $symbol (keys %{$self->{_TRANSITIONS}{$state}}) {
      if ($symbol ne $self->get_epsilon_symbol()) {
        $out .= sprintf("\t('%s'),'%s' --> '%s'\n",$state,$symbol,join('\',\'',$self->get_transition_on($state,$symbol)));
      } else {
        $out .= sprintf("\t('%s'),'%s' --> '%s'\n",$state,$symbol,join('\',\'',$self->get_epsilon_transitions($state)));      
      }
    }
  }  
  return $out;
}

sub serialize {
  my $self = shift;
  my $out = '';
  $out .= sprintf("START :: %s\n",$self->get_start());
  $out .= sprintf("FINAL :: %s\n",join(',',$self->get_final()));
  if (defined($self->get_epsilon_symbol())) {
    $out .= sprintf("EPSILON :: %s\n",$self->get_epsilon_symbol());
  }
  $out .= "\n";
  foreach my $state ($self->get_states()) {
    $out .= sprintf("%s:\n",$state);
    foreach my $symbol (keys %{$self->{_TRANSITIONS}{$state}}) {
      if ($symbol ne $self->get_epsilon_symbol()) {
        $out .= sprintf("$symbol %s\n",join(',',$self->get_transition_on($state,$symbol)));
      } else {
        $out .= sprintf("$symbol %s\n",join(',',$self->get_epsilon_transitions($state)));      
      }
    }
    $out .= sprintf("\n"); 
  }
  return $out;
}

sub generate_random {
  my $self = shift;
}

sub generate_from_strings {
  my $self = shift;
  return "Coming soon!";
}

1;

__END__

=head1 NAME

NFA - A non deterministic finite automata base class

=head1 SYNOPSIS

    use FLAT::Legacy::FA::NFA;

=head1 DESCRIPTION

This module implements a non deterministic finite automata,
including support for epsilon transitions and conversion
to a deterministic finite automata.

=head1 AUTHOR

Brett D. Estrade - <estrabd AT mailcan DOT com>

=head1 CAVEATS

Currently, all states are stored as labels.  There is also
no integrity checking for consistency among the start, final,
and set of all states.

=head1 BUGS

I haven't hit any yet :)

=head1 AVAILABILITY

Perl FLaT Project Website at L<http://perl-flat.sourceforge.net/pmwiki>

=head1 ACKNOWLEDGEMENTS

This suite of modules started off as a homework assignment for a compiler
class I took for my MS in computer science at the University of Southern
Mississippi.  It then became the basis for my MS research. and thesis.

Mike Rosulek has joined the effort, and is heading up the rewrite of
Perl FLaT, which will soon be released as FLaT 1.0.

=head1 COPYRIGHT

This code is released under the same terms as Perl.

=cut
