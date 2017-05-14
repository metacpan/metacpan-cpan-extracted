# $Revision: 1.5 $ $Date: 2006/03/02 21:00:28 $ $Author: estrabd $

package FLAT::Legacy::FA::DFA;

use base 'FLAT::Legacy::FA';
use strict;
use Carp;

use FLAT::Legacy::FA::NFA;
use FLAT::Legacy::FA::RE;
use Data::Dumper;

sub new {
  my $class = shift;
  bless {
    _START_STATE => undef,  # start states -> plural!
    _STATES => [],          # Set of all states
    _FINAL_STATES => [],    # Set of final states, subset of _STATES
    _SYMBOLS => [],         # Symbols
    _TRANSITIONS => {},     # Transition table
  }, $class;
}

sub jump_start {
  my $self = shift;
  my $DFA = FLAT::Legacy::FA::DFA->new();
  my $symbol = shift;
  if (!defined($symbol)) {
    # add 1 state that is the start and final state
    $DFA->add_state(0);
    # set start and final
    $DFA->set_start(0);
    $DFA->add_final(0);
  } else {
    chomp($symbol);
    # add states
    $DFA->add_state(0,1);
    # add symbol
    $DFA->add_symbol($symbol);
    # set start and final
    $DFA->set_start(0);
    $DFA->add_final(1);
    # add single transition
    $DFA->add_transition(0,$symbol,1);
  }
  return $DFA;
}

sub load_file {
  my $self = shift;
  my $file = shift;
  if (-e $file) {
    open (DFA,"<$file");
    my $string = undef;
    while (<DFA>) {
      $string .= $_;
    }
    close (DFA);
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
      } else {
        print STDERR "WARNING: $1 is not a valid header...\n";
      }
    }
  }  
}

sub clone {
  my $self = shift;
  my $DFA = FLAT::Legacy::FA::DFA->new();
  $DFA->add_state($self->get_states());
  $DFA->add_final($self->get_final());
  $DFA->add_symbol($self->get_symbols());
  $DFA->set_start($self->get_start());
  foreach my $state ($self->get_states()) {
    foreach my $symbol (keys %{$self->{_TRANSITIONS}{$state}}) {
      $DFA->add_transition($state,$symbol,$self->{_TRANSITIONS}{$state}{$symbol});
    }
  }
  return $DFA;
}

sub to_nfa {
  my $self = shift;
  my $NFA = FLAT::Legacy::FA::NFA->new();
  $NFA->add_state($self->get_states());
  $NFA->add_final($self->get_final());
  $NFA->add_symbol($self->get_symbols());
  $NFA->set_start($self->get_start());
  foreach my $state ($self->get_states()) {
    foreach my $symbol (keys %{$self->{_TRANSITIONS}{$state}}) {
      $NFA->add_transition($state,$symbol,$self->{_TRANSITIONS}{$state}{$symbol});
    }
  }
  return $NFA;  
}

sub minimize() {
  my $self = shift;
  my @PI1 = ();
  # Anon sub used to get group #
  my $state2group = sub {
    my $array = shift;
    my $state = shift;
    my $c = 0;
    foreach my $x (@{$array}) {
      foreach my $y (@{$x}) {
	return $c if ($y eq $state);
      }
      $c++;
    }
  };
  # Anon sub attempts to identify identical 2d arrays
  my $getsig = sub {
     my $array = shift;
     my @str = ();
     foreach my $x (@{$array}) {
       my $str = crypt(join('',@{$x}),0);
       push(@str,$str);
     }
     @str = sort(@str);
     return join('',@str);  
   };  
  # Anon sub removes duplicate and dead state
  my $cleanup = sub {
    my $oldname = shift;
    my $newname = shift;
    my $i = 0;
    # will add $newstate as long as it is not already there
    my @new = ();
    foreach my $state ($self->get_states()) {
      # just remove state
      if ($state ne $oldname) {
	push(@new,$state);
      }
      $self->{_STATES} = [@new];
    }
    # replace name if start state
    if ($self->is_start($oldname)) {
      $self->set_start($newname);
    }
    # replace transitions
    foreach my $state (keys %{$self->{_TRANSITIONS}}) {
      foreach my $symbol (keys %{$self->{_TRANSITIONS}{$state}}) {
	# rename destination states
	if ($self->{_TRANSITIONS}{$state}{$symbol} eq $oldname) {
	  $self->{_TRANSITIONS}{$state}{$symbol} = $newname;
	}
	# rename start state
	if ($state eq $oldname) {
   	  $self->add_transition($newname,$symbol,$self->{_TRANSITIONS}{$state}{$symbol});  
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
        if ($self->is_final($newname)) {
	  $self->remove_final($oldname);
	} else {
  	  $self->{_FINAL_STATES}[$i] = $newname; 
        }
      }
      $i++;
    }
    return;
  };
  # Step 1 - create a group containing 2 sets of states: accepting (F) and non-accepting (S-F)
  my @tmp = ();
  foreach ($self->get_states()) {
    if (!$self->is_final($_)) {
      push(@tmp,$_);
    }
  }
  push(@PI1,[$self->get_final()]);
  push(@PI1,[@tmp]);
  undef @tmp;
  # Steps 2 & 3 - get final group of partitions through an iterative process
  # ...aka - figure out what states can be merged into one
  my $sig_before = 'x';
  my $sig_after = 'y';
  while ($sig_before ne $sig_after) {
    # print Dumper(@PI1);
    my %PI2 = ();
    my $group_number = 0;
    foreach my $group_ref (@PI1) {
      foreach my $group_state (@{$group_ref}) {
	my $mygroup = $state2group->(\@PI1,$group_state); # seed with own group number
	foreach my $symbol ($self->get_symbols()) {
	  if ($self->has_transition_on($group_state,$symbol)) {
       	    my $trans_to_group = $state2group->(\@PI1,$self->get_transition_on($group_state,$symbol));
	    $mygroup .= $trans_to_group.$symbol;
	  }
	}
	if (defined($mygroup)) {
	  if (!defined($PI2{$mygroup})) {
	    $PI2{$mygroup} = [];
	  }
	  push(@{$PI2{$mygroup}},$group_state);
	} 
      }
      $group_number++;
    }
    # copy to @PI1
    @PI1 = sort(@PI1);
    $sig_before = $getsig->(\@PI1);
    @PI1 = ();
    foreach my $g (keys(%PI2)) {
      push(@PI1,$PI2{$g});      
    }
    @PI1 = sort(@PI1);
    $sig_after = $getsig->(\@PI1);
  } 
  # Steps 4 & 5 - reduce final subgroups into a single representative
  my @removed = ();
  foreach my $group_ref (@PI1) {
    my $rep = shift(@{$group_ref});
    foreach my $group_state (@{$group_ref}) {
      foreach my $symbol ($self->get_symbols) {
	my $trans = $self->get_transition_on($group_state);
	if (defined($trans)) {
	  $self->add_transition($rep,$symbol,$trans);
	}	
      }
      $cleanup->($group_state,$rep);        
      #print STDERR "removed $group_state\n";
      push(@removed,$group_state);
    }
  }
  return @removed;
}

sub delete_state {
  my $self = shift();
  my @del_states = @_;
  foreach my $del_state (@del_states) {
    if ($del_state eq $self->get_start()) {
      print STDERR "WARNING: The start state, $del_state, is being deleted!\n";
      $self->set_start('');
    } 
    if ($self->is_final($del_state)) {
      print STDERR "WARNING: A final state, $del_state, is being deleted!\n";
      my $c = 0;
      foreach my $f ($self->get_final()) {
	if ($f eq $del_state) {
	  delete($self->{_FINAL_STATES}[$c]);
	  last;
	}
	$c++;
      }
    }
    my @new = ();
    foreach my $f ($self->get_states()) {
      if ($f ne $del_state) {
	push(@new,$f);
      }
      $self->{_STATES} = [@new];
    }
    if (defined($self->{_TRANSITIONS}{$del_state})) {
      delete($self->{_TRANSITIONS}{$del_state});
    }
    # delete transitions
    foreach my $state (keys %{$self->{_TRANSITIONS}}) {
      foreach my $symbol (keys %{$self->{_TRANSITIONS}{$state}}) {
        my $trans = $self->get_transition_on($state,$symbol);
	if (defined($trans)) {
          if ($trans eq $del_state) {
	    delete($self->{_TRANSITIONS}{$state}{$symbol});
	  }
	}
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
          # rename destination states
	  if ($self->{_TRANSITIONS}{$state}{$symbol} eq $oldname) {
	    $self->{_TRANSITIONS}{$state}{$symbol} = $newname;
	  }
	  # rename start state
	  if ($state eq $oldname) {
   	    $self->add_transition($newname,$symbol,$self->{_TRANSITIONS}{$state}{$symbol});  
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

# Adds symbol
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
	  $self->add_transition($state,$newsymbol,$self->{_TRANSITIONS}{$state}{$symbol});
	  delete($self->{_TRANSITIONS}{$state}{$symbol});
	}   
      }	
    }
  } else {
    print STDERR "Warning: '$oldsymbol' is not a current symbol\n";
  }
  return;
}

sub add_transition {
  my $self = shift;
  my $state = shift;
  my $symbol = shift;
  $self->{_TRANSITIONS}{$state}{$symbol} = shift;
  return;
}

sub get_transition_on {
  my $self = shift;
  my $state = shift;
  my $symbol = shift;
  my $ret = undef;
  if ($self->is_state($state) && $self->is_symbol($symbol)) {  
    if (defined($self->{_TRANSITIONS}{$state}{$symbol})) {  
      $ret = $self->{_TRANSITIONS}{$state}{$symbol};
    }
  }
  return $ret;  
}

sub reverse_dfa {
  my $self = shift;
  print "Convert to NFA, reverse that, then convert back to DFA and minimize...\n";
}

sub to_gdl {
  my $self = shift;
  my $gdl = "graph: {\ndisplay_edge_labels: yes \n";
  foreach my $state ($self->get_states()) {
    my $style = "borderstyle: solid ";
    if ($self->is_final($state)) {
      $style = "borderstyle:double bordercolor:red";
    }
    # define node (state)
    $gdl .= "node: { title:\"$state\" shape:circle $style }\n";
    # define transitions
    foreach my $symbol ($self->get_symbols()) {
      if (defined($self->{_TRANSITIONS}{$state}{$symbol})) {
        $gdl .= "edge: { source: \"$state\" target: \"$self->{_TRANSITIONS}{$state}{$symbol}\" label: \"$symbol\" arrowstyle: line }\n";
      }
    }
  }
  $gdl .= "}";
  return $gdl;
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
  $out .= sprintf ("\nTransitions    :\n");
  foreach ($self->get_states()) {
    my $state = $_;
    foreach (keys %{$self->{_TRANSITIONS}{$state}}) {
      my $i = $_;
      my $is_final = '';
      if ($self->is_final($self->{_TRANSITIONS}{$state}{$i})) {
        $is_final = '**';
      }
      $out .= sprintf ("\t('%s'),'%s' --> '%s' %s\n",$state,$i,$self->{_TRANSITIONS}{$state}{$i},$is_final);
    }
  }
  $out .= sprintf "(** denotes final state)\n";
  return $out;
}

sub serialize {
  my $self = shift;
  my $out = '';
  $out .= sprintf("START :: %s\n",$self->get_start());
  $out .= sprintf("FINAL :: ");
  $out .= sprintf("%s\n\n",join(',',$self->get_final()));
  foreach my $state ($self->get_states()) {
    $out .= sprintf("%s:\n",$state);
    foreach my $symbol (keys %{$self->{_TRANSITIONS}{$state}}) {
      $out .= sprintf("$symbol %s\n",$self->get_transition_on($state,$symbol));
    }
    $out .= sprintf("\n"); 
  }
  return $out;
}

sub is_valid {
  my $self = shift;
  my $string = shift;
  my $ok = 0;
  my $bad = 0;
  my $curr = $self->get_start();
  my @symbols = split(//,$string);
  if (defined($curr)) {
    while (@symbols) {
      my $s = shift @symbols;
      # make sure that the symbol is in the alphabet
      if ($self->is_symbol($s)) {
	$curr = $self->get_transition_on($curr,$s);
	# make sure that the transition is defined
	if (!defined($curr)) {
          $bad++;
	  last;
	}      
      } else {
	$bad++;
	last;
      }
    }
    # make sure that no symbols are left in the string,
    #	that the current state (if defined) is a final state
    #	that something $bad has not happened - namely a bad symbol or undefined transition
    if (!@symbols && $self->is_final($curr) && !$bad) {
      $ok++;
    }
  }
  return $ok;
}

sub get_last_state {
  my $self = shift;
  my $string = shift;
  my $ok = 0;
  my $bad = 0;
  my $curr = $self->get_start();
  my $prev = undef;
  my @symbols = split(//,$string);
  if (defined($curr)) {
    while (@symbols) {
      my $s = shift @symbols;
      # make sure that the symbol is in the alphabet
      if ($self->is_symbol($s)) {
	$prev = $curr;
	$curr = $self->get_transition_on($curr,$s);
	# make sure that the transition is defined
	if (!defined($curr)) {
	  last;
	}      
      } else {
	last;
      }
    }
  }
  return $curr;
}

sub get_path {
  my $self = shift;
  my $string = shift;
  my $ok = 0;
  my $bad = 0;
  my $curr = $self->get_start();
  my @symbols = split(//,$string);
  my @path = ();
  push (@path,$curr);  
  if (defined($curr)) {
    while (@symbols) {
      my $s = shift @symbols;
      # make sure that the symbol is in the alphabet
      if ($self->is_symbol($s)) {
	$curr = $self->get_transition_on($curr,$s);
        push (@path,$curr); 
	# make sure that the transition is defined
	if (!defined($curr)) {
	  last;
	}      
      } else {
	last;
      }
    }
  }
  return @path;
}

sub generate_random {
  my $self = shift;
}

sub pump_strings {
  my $self = shift;
  return "Coming soon!";
}

sub init_string_pump {
  my $self = shift;
  return "Coming soon!";
}

sub pump_next {
  my $self = shift;
  return "Coming soon!";
}

1;

__END__

=head1 NAME

DFA - A determinisitic finite automata base class

=head1 SYNOPSIS

    use FLAT::Legacy::FA::DFA;

=head1 DESCRIPTION

This module is implements a deterministic finite automata,
including the testing of strings accepted by the DFA.

=head1 AUTHOR

Brett D. Estrade - <estrabd AT mailcan DOT com>

=head1 CAVEATS

Currently, all states are stored as labels.  There is also
no integrity checking for consistency among the start, final,
and set of all states.

=head1 BUGS

I haven't hit any yet, but every now and then C<minimize> makes me pause, thoughthis might have more to do with my lack of intuition than the minimization being done incorrectly.

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
