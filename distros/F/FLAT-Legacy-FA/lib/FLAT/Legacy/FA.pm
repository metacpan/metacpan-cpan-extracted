# $Revision: 1.5 $ $Date: 2006/03/02 21:00:28 $ $Author: estrabd $

package FLAT::Legacy::FA;

use base 'FLAT';
use strict;
use Carp;

use Data::Dumper;

sub set_start {
  my $self = shift;
  my $state = shift;
  chomp($state);
  $self->{_START_STATE} = $state;
  # add to state list if not already there
  $self->add_state($state);
  return;
}

sub get_start {
  my $self = shift;
  return $self->{_START_STATE};
}

sub is_start {
  my $self = shift;
  my $test = shift;
  chomp($test);
  my $ok = 0;
  if ($self->{_START_STATE} eq $test) {$ok++};
  return $ok;
}

sub add_state {
  my $self = shift;
  foreach my $state (@_) {
    if (!$self->is_state($state)) {
      push(@{$self->{_STATES}},$state);    
    }
  }
  return;
}

# Returns array of states
sub get_states {
  my $self = shift;
  return @{$self->{_STATES}};  
}

sub ensure_unique_states {
  my $self = shift;
  my $NFA1 = shift;
  my $disambigator = shift;
  chomp($disambigator);
  foreach ($self->get_states()) {
    my $state1 = $_;
    while ($NFA1->is_state($state1) && !$self->is_state($disambigator)) {
      $self->rename_state($state1,$disambigator);
      # re-assign $state1 with new name
      $state1 = $disambigator;
      # get new disambiguator just incase this is not unique
      $disambigator = crypt(rand 8,join('',[rand 8, rand 8]));
    }
  }
  return;
}

sub number_states {
  my $self = shift;
  my $number = 0;
  # generate 5 character string of random numbers
  my $prefix = crypt(rand 8,join('',[rand 8, rand 8]));
  # add random prefix to state names
  foreach ($self->get_states()) {
    $self->rename_state($_,$prefix."_$number");
    $number++;
  }
  # rename states as actual numbers    
  $number = 0;
  foreach ($self->get_states()) {
    $self->rename_state($_,$number);
    $number++;
  }
  return;  
}

sub append_state_names {
  my $self = shift;
  my $suffix = shift;
  if (defined($suffix)) {
    chomp($suffix);
  } else {
    $suffix = '';
  }
  foreach ($self->get_states()) {
    $self->rename_state($_,"$_".$suffix);
  }
  return;  
}

sub prepend_state_names {
  my $self = shift;
  my $prefix = shift;
  if (defined($prefix)) {
    chomp($prefix);
  } else {
    $prefix = '';
  }
  foreach ($self->get_states()) {
    $self->rename_state($_,$prefix."$_");
  }
  return;  
}

# Will test if the string passed to it is the same as a label of any state
sub is_state {
  my $self = shift;
  return $self->is_member(shift,$self->get_states());
}

# Adds state to final (accepting) state stack
sub add_final {
  my $self = shift;
  foreach my $state (@_) {
    if (!$self->is_final($state)) {
      # ensure state is in set of states - uniqueness enforced!
      $self->add_state($state);
      if (!$self->is_final($state)) {
	push(@{$self->{_FINAL_STATES}},$state);    
      }
    }
  }
  return;
}

sub remove_final {
  my $self = shift;
  my $remove = shift;
  my $i = 0;
  foreach ($self->get_final()) {
    if ($remove eq $_) {
      splice(@{$self->{_FINAL_STATES}},$i);
    }
    $i++;
  }
  return;
}

# Returns array of final states
sub get_final {
  my $self = shift;
  return @{$self->{_FINAL_STATES}}
}

# Will test if the string passed to it is the same as a label of any state
sub is_final {
  my $self = shift;
  return $self->is_member(shift,$self->get_final());
}

# Adds symbol
sub add_symbol {
  my $self = shift;
  foreach my $symbol (@_) {
    if (!$self->is_symbol($symbol)) {
      push(@{$self->{_SYMBOLS}},$symbol);
    }
  }
  return;
}

# Will test if the string passed to it is the same as a label of any symbol
sub is_symbol {
  my $self = shift;
  return $self->is_member(shift,@{$self->{_SYMBOLS}});
}

# Returns array of all symbols
sub get_symbols {
  my $self = shift;
  return @{$self->{_SYMBOLS}}; 
}

# Returns a hash of all transitions (symbols and next states) for specified state
sub get_transition {
  my $self = shift;
  my $state = shift;
  print Dumper(caller);
  return %{$self->{_TRANSITIONS}{$state}};  
}

sub get_all_transitions {
  my $self = shift;
  return %{$self->{_TRANSITIONS}};
}

sub has_transition_on {
  my $self = shift;
  my $state = shift;
  my $symbol = shift;
  my $ok = 0;
  if (defined($self->{_TRANSITIONS}{$state}{$symbol})) {
    $ok++;
  }
  return $ok;
}

sub has_transitions {
  my $self = shift;
  my $state = shift;
  my $ok = 0;
  if (defined($self->{_TRANSITIONS}{$state})) {
    $ok++;
  }
  return $ok;
}

sub delete_transition {
  my $self = shift;
  my $state = shift;
  my $symbol = shift;
  if ($self->is_state($state) && $self->is_symbol($symbol)) {  
    delete($self->{_TRANSITIONS}{$state}{$symbol});
  }
  return;  
}

sub to_file {
  my $self = shift;
  my $file = shift;
  chomp($file);
  open(FH,">$file");
  print FH $self->to_string();
  close(FH);
}

sub  compliment {
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

# General subroutine used to test if an element is already in an array
sub is_member {
  my $self = shift;
  my $test = shift;
  my $ret = 0;
  if (defined($test)) {
    # This way to test if something is a member is significantly faster..thanks, PM!
    if (grep {$_ eq $test} @_) {
      $ret++;
    }
  }
  return $ret;
}

sub DESTROY {
  return;
}

1;

__END__

=head1 NAME

FA - A finite automata base class

=head1 SYNOPSIS

    use FLAT::Legacy::FA;

=head1 DESCRIPTION

This module is a base finite automata used by NFA and DFA to encompass common functions.  It is probably of no use other than to organize the DFA and NFA modules.

=head1 AUTHOR

Brett D. Estrade - <estrabd AT mailcan DOT com>

=head1 CAVEATS

Currently, all states are stored as labels.  There is also no integrity checking for consistency among the start, final, and set of all states.

=head1 BUGS

I haven't hit any yet :)

=head1 AVAILABILITY

Perl FLaT Project Website at L<http://perl-flat.sourceforge.net/pmwiki>

=head1 ACKNOWLEDGEMENTS

This suite of modules started off as a homework assignment for a compiler class I took for my MS in computer science at the University of Southern Mississippi.  It then became the basis for my MS research. and thesis.

Mike Rosulek has joined the effort, and is heading up the rewrite of Perl FLaT, which will soon be released as FLaT 1.0.

=head1 COPYRIGHT

This code is released under the same terms as Perl.
