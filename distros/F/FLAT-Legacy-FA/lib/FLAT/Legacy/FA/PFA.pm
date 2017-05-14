# $Revision: 1.5 $ $Date: 2006/03/02 21:00:28 $ $Author: estrabd $

package FLAT::Legacy::FA::PFA;

use base 'FLAT::Legacy::FA';
use strict;
use Carp;

use FLAT::Legacy::FA::NFA;
use Data::Dumper;

sub new {
  my $class = shift;
  bless {
    _START_NODES => [],       # start node - subset of nodes to start on;
    _NODES => [],             # nodes - nodes make up nodes in PFA
    _ACTIVE_NODES => [],      # list of active nodes - corresponds to a "node"
    _FINAL_NODES => [],       # Set of final node - a string is accepted when set of active nodes 
                              # is exactly this and end of string is encountered
    _SYMBOLS => [],           # Symbols
    _TRANSITIONS => {},       # Nodal transitions on symbol (gamma functions)
    _EPSILON => 'epsilon',    # how an epsilon transition is represented
    _LAMBDA => 'lambda',      # how lambda transitions is represented
    _TIED => [],              # stores look up of tied nodes; computed when 
                              # $self->find_tied() is called
  }, $class;
}

sub load_file {
  my $self = shift;
  my $file = shift;
  if (-e $file) {
    open (PFA,"<$file");
    my $string = undef;
    while (<PFA>) {
      $string .= $_;
    }
    close (PFA);
    $self->load_string($string);
  }
}

sub load_string {
  my $self = shift;
  my $string = shift;
  my @lines = split("\n",$string);
  my $CURR_NODE = undef;
  foreach (@lines) {
    # strip comments
    $_ =~ s/\s*#.*$//;
    # check if line is a node, transition, or keyword
    if (m/^\s*([\w\d]*)\s*:\s*$/) {
      #print STDERR "Found transitions for node $1\n";
      $self->add_node($1);
      $CURR_NODE = $1;
    } elsif (m/^\s*([\w\d]*)\s*([\w\d,]*)\s*$/ && ! m/^$/) {
      # treat as transition
      #print STDERR "Input: '$1' goes to $2\n";
      my @s = split(',',$2);
      $self->add_transition($CURR_NODE,$1,@s);
      $self->add_symbol($1);
    } elsif (m/^\s*([\w\d]*)\s*::\s*([\w\d,]*)\s*$/ && ! m/^$/) {
      # Check for known header keywords
      my $val = $2;
      if ($1 =~ m/START/i) {
        my @s = split(',',$val);
        $self->set_start(@s);	
      } elsif ($1 =~ m/FINAL/i) {
        my @s = split(',',$val);
	$self->add_final(@s);
      } elsif ($1 =~ m/EPSILON/i) {
        $self->set_epsilon($val);
      } elsif ($1 =~ m/LAMBDA/i) {
        $self->set_lambda($val);
      } else {
        print STDERR "WARNING: $1 is not a valid header...\n";
      }
    }
  }
  $self->find_tied();
  return;
}

sub jump_start {
  my $self = shift;
  my $PFA = FLAT::Legacy::FA::PFA->new();
  my $symbol = shift;
  if (!defined($symbol)) {
    $symbol = $PFA->get_epsilon_symbol();
  } else {
    chomp($symbol);
  }
  my $newstart = crypt(rand 8,join('',[rand 8, rand 8]));
  my $newfinal = crypt(rand 8,join('',[rand 8, rand 8]));
  # add states
  $PFA->add_node($newstart,$newfinal);
  # add symbol
  $PFA->add_symbol($symbol);
  # set start and final
  $PFA->set_start($newstart);
  $PFA->add_final($newfinal);
  # add single transition
  $PFA->add_transition($newstart,$symbol,$newfinal);
  return $PFA;
}

sub find_tied {
  my $self = shift;
  my $lambda = $self->get_lambda_symbol();
  my %tied = ();
  foreach my $node ($self->get_nodes()) {
    my @trans = $self->get_lambda_transitions($node);
    if (@trans) {
      my $name = $self->serialize_name(@trans);
      if (!defined($tied{$name})) {
	$tied{$name} = [];
      }
      push(@{$tied{$name}},$node);
    }
  }
  foreach my $t (keys(%tied)) {
    push(@{$self->{_TIED}},[@{$tied{$t}}]);
  }
  return; 
}

sub get_tied {
  my $self = shift;
  return @{$self->{_TIED}}; 
}

sub has_tied {
  my $self = shift;
  my @testset = @_;
  my $ok = 0;
  foreach my $tied ($self->get_tied()) {
    my $allornone = 0;
    foreach my $tn (@{$tied}) {
      #if $tn is in @testset, increment $allornone
      if ($self->is_member($tn,@testset)) {
        $allornone++;
      }
    }
    # if $allornone is equal to the number of items in the tied set,
    # assume that the entire set is in @testset thus satisfiying the
    # tied requirement for lambda transitions
    if ($allornone == @{$tied}) {
      $ok++;
      last;
    }
  }
  return $ok; 
}

sub extract_tied {
  my $self = shift;
  my @testset = @_;
  my @ret = ();
  foreach my $tied ($self->get_tied()) {
    my $count = 0;
    my @tmp = ();
    foreach my $tn (@{$tied}) {
      #if $tn is in @testset, increment $count
      if ($self->is_member($tn,@testset)) {
        push(@tmp,$tn);
        $count++;
      }
    }
    if ($count == @{$tied}) {
      foreach (@tmp) {
        if (!$self->is_member($_,@ret)) {
	  push(@ret,$_);
	}
      }
    }
  }
  return @ret;
}

sub to_nfa {
  my $self = shift;
  my @Dstates = (); # stack of new states to find transitions for 
  my %Dtran =(); # hash of serialized state names that have been searched
  # New NFA object reference
  my $NFA = FLAT::Legacy::FA::NFA->new();
  $NFA->set_epsilon($self->get_epsilon_symbol());
  # Initialize NFA start state by performing e-closure on the PFA start state
  my @Start = $self->get_start();
  # Add this state to Dstates - subsets stored as anonymous arrays (no faking here!)
  push(@Dstates,[sort(@Start)]);
  # Serialize subset into new state name - i.e, generate string-ified name
  my $ns = $self->serialize_name(@Start);
  # add to Dtran as well for tracking
  $Dtran{$ns}++;
  # serialize final node set
  my $final_state =  $self->serialize_name($self->get_final());
  # set this state as final - since there will be only ONE!
  $NFA->add_final($final_state);
  $NFA->add_state($final_state);
  # Add start state to NFA (placeholder Dtran not used)
  $NFA->set_start($ns);
  # Add new state (serialized name) to NFA state array
  $NFA->add_state($ns);
  # Loop until Dstate stack is exhausted
  while (@Dstates) {
    # shift next state off to check
    my @T = @{pop @Dstates};
    # Serialize subset into a string name
    my $CURR_STATE = $self->serialize_name(@T);
    #print "$CURR_STATE\n";
    # loop over each input symbol
    foreach my $symbol ($self->get_symbols()) {
      if ($symbol eq $self->get_lambda_symbol() && $self->has_tied(@T)) {
        # get flattened list of all tied nodes in @T
        my @tied = $self->extract_tied(@T);
        my @new = ();
	my @next = ();
	foreach my $t (@tied) {
	  my @trans = $self->get_lambda_transitions($t);
          foreach (@trans) {
	    if (!$self->is_member($_,@new)) {
	      push(@new,$_);
	    } 
          } # foreach (@trans)
	} # foreach my $t (@tied)
        # @next contains new, obviously
	push(@next,@new);
	# @next also contains @T - @tied
	push(@next,$self->compliment(\@T,\@tied));
	# see if the resulting state can be added to @Dstates
        my $state = $self->serialize_name(@next);
	if (!defined($Dtran{$state})) {
	  push(@Dstates,[sort(@next)]);
          $Dtran{$state}++;
	  # add transition to $NFA
	}		
	$NFA->add_transition($CURR_STATE,$self->get_epsilon_symbol(),$state);		
      } elsif ($symbol ne $self->get_lambda_symbol()) {
	foreach my $node (@T) {
          if (defined($self->{_TRANSITIONS}{$node}{$symbol})) {
	    my @new = $self->get_transition_on($node,$symbol);
	    foreach my $new (@new) {
	      my @next = $self->compliment(\@T,[$node]);
	      push(@next,$new);
              my $state = $self->serialize_name(@next);
	      if (!defined($Dtran{$state})) {
		push(@Dstates,[sort(@next)]);
        	$Dtran{$state}++;
	      }
	      # add transition to $NFA
              $NFA->add_transition($CURR_STATE,$symbol,$state);		
	    } # foreach my $new (@new)
	  }
	} # foreach my $node (@T)
      }
    } # foreach my $symbol ($self->get_symbols())
  }
  return $NFA;
}

sub  serialize_name {
  my $self = shift;
  # note that the nature of Perl subs causes @_ to be flattened
  my $name = join('_',sort(@_));
  return $name;
}

sub set_start {
  my $self = shift;
  # flushes out current start nodes, and saves in entire list of provided nodes
  $self->{_START_NODES} = [@_];
  # these nodes are also reset as the default active nodes
  $self->set_active(@_);
  # add to node list if not already there
  $self->add_node(@_);
  return;
}

sub get_start {
  my $self = shift;
  return @{$self->{_START_NODES}};
}

sub set_active {
  my $self = shift;
  $self->{_ACTIVE_NODES} = [@_];
  # add to node list if not already there
  return;
}

sub get_active {
  my $self = shift;
  return @{$self->{_ACTIVE_NODES}};
}

sub add_node {
  my $self = shift;
  foreach my $node (@_) {
    if (!$self->is_node($node)) {
      push(@{$self->{_NODES}},$node);    
    }
  }
  return;
}

sub get_nodes {
  my $self = shift;
  return @{$self->{_NODES}};  
}

sub add_transition {
  my $self = shift;
  my $node = shift;
  my $symbol = shift;
  $self->add_symbol($symbol);
  foreach my $next (@_) {
    if (!$self->is_member($next,@{$self->{_TRANSITIONS}{$node}{$symbol}})) {
      push (@{$self->{_TRANSITIONS}{$node}{$symbol}},$next);
    }
  }
  return;
}

sub get_transition_on {
  my $self = shift;
  my $node = shift;
  my $symbol = shift;
  my @ret = undef;
  if ($self->is_node($node) && $self->is_symbol($symbol)) {  
    if (defined($self->{_TRANSITIONS}{$node}{$symbol})) {
      @ret = @{$self->{_TRANSITIONS}{$node}{$symbol}};
    }
  }
  return @ret;  
}

sub is_start {
  my $self = shift;
  return $self->is_member(shift,$self->get_start());
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
  my $node = shift;
  my @ret = ();
  if ($self->is_node($node)) {
    if (defined($self->{_TRANSITIONS}{$node}{$self->get_epsilon_symbol()})) {
      @ret = @{$self->{_TRANSITIONS}{$node}{$self->get_epsilon_symbol()}};
    }
  }
  return @ret;  
}

sub delete_epsilon {
  my $self = shift;
  delete($self->{_EPSILON});
  return;
}

sub set_lambda {
  my $self = shift;
  my $lambda = shift;
  $self->{_LAMBDA} = $lambda;
  return;
}

sub get_lambda_symbol {
  my $self = shift;
  return $self->{_LAMBDA};
}

sub get_lambda_transitions {
  my $self = shift;
  my $node = shift;
  my @ret = ();
  if ($self->is_node($node)) {
    if (defined($self->{_TRANSITIONS}{$node}{$self->get_lambda_symbol()})) {
      @ret = @{$self->{_TRANSITIONS}{$node}{$self->get_lambda_symbol()}};
    }
  }
  return @ret;  
}

sub delete_lambda {
  my $self = shift;
  delete($self->{_LAMBDA});
  return;
}

sub is_node {
  my $self = shift;
  return $self->is_member(shift,$self->get_nodes());
}

sub add_final {
  my $self = shift;
  foreach my $node (@_) {
    if (!$self->is_final($node)) {
      push(@{$self->{_FINAL_NODES}},$node);    
    }
  }
  return;
}

sub get_final {
  my $self = shift;
  return @{$self->{_FINAL_NODES}}
}

sub is_final {
  my $self = shift;
  return $self->is_member(shift,$self->get_final());
}

sub clone {
  my $self = shift;
  my $PFA = FLAT::Legacy::FA::PFA->new();
  $PFA->add_node($self->get_nodes());
  $PFA->add_final($self->get_final());
  $PFA->add_symbol($self->get_symbols());
  $PFA->set_start($self->get_start());
  $PFA->set_epsilon($self->get_epsilon_symbol);
  $PFA->set_lambda($self->get_lambda_symbol);
  foreach my $node ($self->get_nodes()) {
    foreach my $symbol (keys %{$self->{_TRANSITIONS}{$node}}) {
      $PFA->add_transition($node,$symbol,@{$self->{_TRANSITIONS}{$node}{$symbol}});
    }
  }
  return $PFA;
}

sub append_pfa {
  my $self = shift;
  my $PFA = shift;
  # clone $PFA
  my $PFA1 = $PFA->clone();
  # pinch off self - ensures a single final node to append PFA1 to
  $self->pinch();
  # ensure unique node names
  $self->ensure_unique_nodes($PFA1,crypt(rand 8,join('',[rand 8, rand 8])));
  # sychronize epsilon symbol
  if ($PFA1->get_epsilon_symbol() ne $self->get_epsilon_symbol()) {
    $PFA1->rename_symbol($PFA1->get_epsilon_symbol(),$self->get_epsilon_symbol());  
  }  
  # add new nodes from PFA1
  foreach my $node ($PFA1->get_nodes()) {
    $self->add_node($node);
  };
  # add new symbols from PFA1
  foreach my $symbol ($PFA1->get_symbols()) { 
    $self->add_symbol($symbol);
  }
  # add epsilon transitions from PFA1
  foreach my $node (keys %{$PFA1->{_TRANSITIONS}}) {
    foreach my $symbol (keys %{$PFA1->{_TRANSITIONS}{$node}}) {
      $self->add_transition($node,$symbol,@{$PFA1->{_TRANSITIONS}{$node}{$symbol}});
    }
  }
  # remove current final node and saves it for future reference
  my $oldfinal = pop(@{$self->{_FINAL_NODES}});
  # add new epsilon transition from the old final node of $self to the start nodes of PFA1
  $self->add_transition($oldfinal,$self->get_epsilon_symbol(),$PFA1->get_start());
  # mark the final node of PFA1 as the final node of $self
  $self->add_final($PFA1->get_final());
  # nodes not renumbered - can done explicity by user
  return;
}

sub prepend_pfa {
  my $self = shift;
  my $PFA = shift;
  # clone $PFA
  my $PFA1 = $PFA->clone();
  # pinch off $PFA1 to ensure a single final node to join self to
  $PFA1->pinch();
  # ensure unique node names
  $self->ensure_unique_nodes($PFA1,crypt(rand 8,join('',[rand 8, rand 8])));
  # sychronize epsilon symbol
  if ($PFA1->get_epsilon_symbol() ne $self->get_epsilon_symbol()) {
    $PFA1->rename_symbol($PFA1->get_epsilon_symbol(),$self->get_epsilon_symbol());  
  }  
  # add new nodes from PFA1
  foreach my $node ($PFA1->get_nodes()) {
    $self->add_node($node);
  };
  # add new symbols from PFA1
  foreach my $symbol ($PFA1->get_symbols()) { 
    $self->add_symbol($symbol);
  }
  # add transitions from PFA1
  foreach my $node (keys %{$PFA1->{_TRANSITIONS}}) {
    foreach my $symbol (keys %{$PFA1->{_TRANSITIONS}{$node}}) {
      $self->add_transition($node,$symbol,@{$PFA1->{_TRANSITIONS}{$node}{$symbol}});
    }
  }
  # remove current final node of $PFA1 and saves it for future reference
  my $oldfinal = pop(@{$PFA1->{_FINAL_NODES}});
  # add new epsilon transition from the old final node of $PFA1 to the start nodes of $self
  $self->add_transition($oldfinal,$self->get_epsilon_symbol(),$self->get_start());
  # mark the final node of PFA1 as the final node of $self
  $self->set_start($PFA1->get_start());
  # nodes not renumbered - can done explicity by user
  return;
}

sub or_pfa {
  my $self = shift;
  my $PFA1 = shift;
  # (NOTE: epsilon pinch not used)
  $self->ensure_unique_nodes($PFA1,crypt(rand 8,join('',[rand 8, rand 8])));
  # sychronize epsilon symbol
  if ($PFA1->get_epsilon_symbol() ne $self->get_epsilon_symbol()) {
    $PFA1->rename_symbol($PFA1->get_epsilon_symbol(),$self->get_epsilon_symbol());  
  }  
  # add new nodes from PFA1
  foreach my $node ($PFA1->get_nodes()) {
    $self->add_node($node);
  };
  # add new symbols from PFA1
  foreach my $symbol ($PFA1->get_symbols()) { 
    $self->add_symbol($symbol);
  }
  # add transitions from PFA1
  foreach my $node (keys %{$PFA1->{_TRANSITIONS}}) {
    foreach my $symbol (keys %{$PFA1->{_TRANSITIONS}{$node}}) {
      $self->add_transition($node,$symbol,@{$PFA1->{_TRANSITIONS}{$node}{$symbol}});
    }
  }
  # save old start nodes
  my @start1 = $self->get_start();
  my @start2 = $PFA1->get_start();
  # create new start node
  my $newstart = crypt(rand 8,join('',[rand 8, rand 8]));
  $self->add_node($newstart);
  # set this new node as the start
  $self->set_start($newstart);
  # add the final node from PFA1 
  $self->add_final($PFA1->get_final());
  # create transitions to old start nodes from new start node
  $self->add_transition($newstart,$self->get_epsilon_symbol(),@start1);
  $self->add_transition($newstart,$self->get_epsilon_symbol(),@start2);
  # pinch the final states into a single final state - required for PFA->to_nfa to work properly
  $self->pinch();
  return;
}

sub interleave_pfa {
  my $self = shift;
  my $PFA1 = shift;
  # (NOTE: epsilon pinch not used)
  # ensure unique node names
  $self->ensure_unique_nodes($PFA1,crypt(rand 8,join('',[rand 8, rand 8])));
  # sychronize epsilon symbol
  if ($PFA1->get_epsilon_symbol() ne $self->get_epsilon_symbol()) {
    $PFA1->rename_symbol($PFA1->get_epsilon_symbol(),$self->get_epsilon_symbol());  
  }  
  # sychronize lambda symbol
  if ($PFA1->get_lambda_symbol() ne $self->get_lambda_symbol()) {
    $PFA1->rename_symbol($PFA1->get_lambda_symbol(),$self->get_lambda_symbol());  
  }  
  # add new nodes from PFA1
  foreach my $node ($PFA1->get_nodes()) {
    $self->add_node($node);
  }
  # add new symbols from PFA1
  foreach my $symbol ($PFA1->get_symbols()) { 
    $self->add_symbol($symbol);
  }
  # add transitions from PFA1
  foreach my $node (keys %{$PFA1->{_TRANSITIONS}}) {
    foreach my $symbol (keys %{$PFA1->{_TRANSITIONS}{$node}}) {
      $self->add_transition($node,$symbol,@{$PFA1->{_TRANSITIONS}{$node}{$symbol}});
    }
  }
  # save old start nodes
  my @start1 = $self->get_start();
  my @start2 = $PFA1->get_start();
  # create new start node
  my $newstart = crypt(rand 8,join('',[rand 8, rand 8]));
  $self->add_node($newstart);
  # set this new node as the start
  $self->set_start($newstart);
  # create transitions to old start nodes from new start node
  $self->add_transition($newstart,$self->get_lambda_symbol(),@start1);
  $self->add_transition($newstart,$self->get_lambda_symbol(),@start2);
  # create new final node
  # save final nodes from self and PFA1 
  my @final_tmp = $self->get_final();
  push (@final_tmp,$PFA1->get_final());
  # reset final node array
  my $newfinal = crypt(rand 8,join('',[rand 8, rand 8]));
  $self->add_node($newfinal);
  $self->{_FINAL_NODES} = [$newfinal];
  # add a lambda transition from each of the old final nodes to the new final node
  foreach my $final_tmp (@final_tmp) {
    $self->add_transition($final_tmp,$self->get_lambda_symbol(),$newfinal);  
  }
  return;
}

sub kleene {
  my $self = shift;
  my $newstart = crypt(rand 8,join('',[rand 8, rand 8]));
  my $newfinal = crypt(rand 8,join('',[rand 8, rand 8]));
  # pinch off self - ensures a single final node
  $self->pinch();
  my @oldstart = $self->get_start();
  my $oldfinal = pop(@{$self->{_FINAL_NODES}});
  # add new nodes
  $self->add_node($newstart,$newfinal);
  # set start
  $self->set_start($newstart);
  # set final
  $self->add_final($newfinal);
  # $oldfinal->$oldstart
  $self->add_transition($oldfinal,$self->get_epsilon_symbol(),@oldstart);  
  # $newstart->$oldstart
  $self->add_transition($newstart,$self->get_epsilon_symbol(),@oldstart);
  # $oldfinal->$newfinal
  $self->add_transition($oldfinal,$self->get_epsilon_symbol(),$newfinal);
  # $newstart->$newfinal
  $self->add_transition($newstart,$self->get_epsilon_symbol(),$newfinal); 
  return;
}

sub pinch {
  my $self = shift;
  # do only if there is more than one final node
  my $newfinal = join(',',@{$self->{_FINAL_NODES}});
  $self->add_node($newfinal);
  while (@{$self->{_FINAL_NODES}}) {
    # design decision - remove all final nodes so that the common
    # one is the only final node and all former final nodes have an
    # epsilon transition to it - could prove costly for NFA->to_dfa, so
    # this could change
    my $node = pop(@{$self->{_FINAL_NODES}});
    # add new transition unless it is to the final node itself
    if ($node ne $newfinal) {
      $self->add_transition($node,$self->get_epsilon_symbol(),$newfinal)
    }
  }
  $self->add_final($newfinal);
  # FA->number_nodes() could be used here, but the user may not
  # want the nodes renamed, so it can be used explicitly
  return;
}

sub rename_node {
  my $self = shift;
  my $oldname = shift;
  my $newname = shift;
  # make sure $oldname is an actual node in this FA
  if (!$self->is_node($newname)) {
    if ($self->is_node($oldname)) {
      # replace name in _NODES array
      my $i = 0;
      foreach ($self->get_nodes()) {
	if ($_ eq $oldname) {
          $self->{_NODES}[$i] = $newname; 
       	  last;
	}
	$i++;
      }
      # replace name if start node
      if ($self->is_start($oldname)) {
        my $i = 0;
	foreach my $n ($self->get_start()) {
	  if ($n eq $oldname) {
	    $self->{_START_NODES}[$i] = $newname;
	  }
	  $i++;
	}
      }
      # replace transitions
      foreach my $node (keys %{$self->{_TRANSITIONS}}) {
	foreach my $symbol (keys %{$self->{_TRANSITIONS}{$node}}) {
	  my $j = 0;
          foreach my $next (@{$self->{_TRANSITIONS}{$node}{$symbol}}) {
            # rename destination nodes
	    if ($self->{_TRANSITIONS}{$node}{$symbol}[$j] eq $oldname) {
	      $self->{_TRANSITIONS}{$node}{$symbol}[$j] = $newname;
	    }
            $j++;
	  }
	  # rename start node
	  if ($node eq $oldname) {
   	    $self->add_transition($newname,$symbol,@{$self->{_TRANSITIONS}{$node}{$symbol}});  
	  }
	}	
        if ($node eq $oldname) {
  	  # delete all transitions of old node
	  delete($self->{_TRANSITIONS}{$node});
	}
      }
      # replace final nodes
      $i = 0;
      foreach ($self->get_final()) {
	if ($_ eq $oldname) {
          $self->{_FINAL_NODES}[$i] = $newname; 
	}
	$i++;
      }
      # replace tied nodes
      $i = 0;
      foreach ($self->get_tied()) {
        my $tied = $_;
        my $j = 0;
	foreach my $node (@{$tied}) {
	  if ($node eq $oldname) {
	    $self->{_TIED}[$i]->[$j] = $newname;
	  }
	  $j++;
	}
	$i++;
      }      
    } else {
      print STDERR "Warning: $oldname is not a current node\n";
    }
  } else {
    print STDERR "Warning: $newname is a current node\n";  
  }
  return;
}

sub ensure_unique_nodes {
  my $self = shift;
  my $PFA1 = shift;
  my $disambigator = shift;
  chomp($disambigator);
  foreach ($self->get_nodes()) {
    my $node1 = $_;
    while ($PFA1->is_node($node1) && !$self->is_node($disambigator)) {
      $self->rename_node($node1,$disambigator);
      # re-assign $node1 with new name
      $node1 = $disambigator;
      # get new disambiguator just incase this is not unique
      $disambigator = crypt(rand 8,join('',[rand 8, rand 8]));
    }
  }
  return;
}

sub number_nodes {
  my $self = shift;
  my $number = 0;
  # generate 5 character string of random numbers
  my $prefix = crypt(rand 8,join('',[rand 8, rand 8]));
  # add random prefix to node names
  foreach ($self->get_nodes()) {
    $self->rename_node($_,$prefix."_$number");
    $number++;
  }
  # rename nodes as actual numbers    
  $number = 0;
  foreach ($self->get_nodes()) {
    $self->rename_node($_,$number);
    $number++;
  }
  return;  
}

sub append_node_names {
  my $self = shift;
  my $suffix = shift;
  if (defined($suffix)) {
    chomp($suffix);
  } else {
    $suffix = '';
  }
  foreach ($self->get_nodes()) {
    $self->rename_node($_,"$_".$suffix);
  }
  return;  
}

sub prepend_node_names {
  my $self = shift;
  my $prefix = shift;
  if (defined($prefix)) {
    chomp($prefix);
  } else {
    $prefix = '';
  }
  foreach ($self->get_nodes()) {
    $self->rename_node($_,$prefix."$_");
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
    foreach my $node (keys %{$self->{_TRANSITIONS}}) {
      foreach my $symbol (keys %{$self->{_TRANSITIONS}{$node}}) {
        if ($symbol eq $oldsymbol) {
	  $self->add_transition($node,$newsymbol,@{$self->{_TRANSITIONS}{$node}{$symbol}});
	  delete($self->{_TRANSITIONS}{$node}{$symbol});
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

sub info {
  my $self = shift;
  my $out = ''; 
  $out .= sprintf ("Nodes          : ");
  foreach ($self->get_nodes()) {
    $out .= sprintf "'$_' ";
  }
  $out .= sprintf ("\nStart State    : '%s'\n",join(',',$self->get_start()));
  $out .= sprintf ("Final State    : '%s'\n",join(',',$self->get_final()));
  $out .= sprintf ("Alphabet       : ");
  foreach ($self->get_symbols()) {
    $out .= sprintf "'$_' ";
  }
  if (defined($self->get_epsilon_symbol())) {
    $out .= sprintf("\nEPSILON Symbol : '%s'",$self->get_epsilon_symbol());
  }  
  if (defined($self->get_lambda_symbol())) {
    $out .= sprintf("\nLAMBDA Symbol  : '%s'",$self->get_lambda_symbol());
  }
  $out .= sprintf ("\nTied Nodes     : ");
  foreach my $t ($self->get_tied()) {
    $out .= sprintf(join(',',@{$t}));
    $out .= '; ';
  }
  $out .= sprintf ("\nTransitions    :\n");
  foreach my $node ($self->get_nodes()) {
    foreach my $symbol (keys %{$self->{_TRANSITIONS}{$node}}) {
      if ($symbol ne $self->get_epsilon_symbol() && $symbol ne $self->get_lambda_symbol()) {
        $out .= sprintf("\t('%s'),'%s' --> '%s'\n",$node,$symbol,join('\',\'',$self->get_transition_on($node,$symbol)));
      } elsif ($symbol ne $self->get_lambda_symbol()) {
        $out .= sprintf("\t('%s'),'%s' --> '%s'\n",$node,$symbol,join('\',\'',$self->get_epsilon_transitions($node)));      
      } else {
        $out .= sprintf("\t('%s'),'%s' --> '%s'\n",$node,$symbol,join('\',\'',$self->get_lambda_transitions($node)));
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
  if (defined($self->get_lambda_symbol())) {
    $out .= sprintf("LAMBDA :: %s\n",$self->get_lambda_symbol());
  }
  $out .= "\n";
  foreach my $node ($self->get_nodes()) {
    $out .= sprintf("%s:\n",$node);
    foreach my $symbol (keys %{$self->{_TRANSITIONS}{$node}}) {
      if ($symbol ne $self->get_epsilon_symbol() && $symbol ne $self->get_lambda_symbol()) {
        $out .= sprintf("$symbol %s\n",join(',',$self->get_transition_on($node,$symbol)));
      } elsif ($symbol ne $self->get_lambda_symbol()) {
        $out .= sprintf("$symbol %s\n",join(',',$self->get_epsilon_transitions($node)));      
      } else {
        $out .= sprintf("$symbol %s\n",join(',',$self->get_lambda_transitions($node)));            
      }
    }
    $out .= sprintf("\n"); 
  }
  return $out;
}

1;

__END__

=head1 NAME

PFA - A parallel finite automata base class

=head1 SYNOPSIS

    use FLAT::Legacy::FA::PFA;

=head1 DESCRIPTION

This module is implements a paralle finite automata,
and the conversion of such to a non deterministic
finite automata;

One key between PFA implementation an PFA & DFA is that the PFA
may contain more than one start node since it may depict
threads of concurrent execution.  The main purpose of this 
module is to convert a PFA to an PFA.

=head1 AUTHOR

Brett D. Estrade - <estrabd AT mailcan DOT com>

=head1 CAVEATS

Currently, all nodes are stored as labels.  There is also
no integrity checking for consistency among the start, final,
and set of all nodes.

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
