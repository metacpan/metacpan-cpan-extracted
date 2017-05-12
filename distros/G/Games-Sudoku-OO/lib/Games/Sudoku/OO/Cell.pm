#!/usr/local/bin/perl -w

package Games::Sudoku::OO::Cell;

use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %args = (possibles=>undef, @_);  
  my $self = {}; 
  %{$self->{POSSIBLES}} = %{$args{possibles}}; 
  $self->{VALUE} = undef;
  bless ($self, $class);
  return $self;
}

sub getValue {
  my $self = shift;
  return $self->{VALUE};
}

sub setValue {
  my $self = shift;
  $self->{VALUE} = shift;
  ($self->{ROW})->notifySolved($self);
  ($self->{COLUMN})->notifySolved($self);
  ($self->{SQUARE})->notifySolved($self);
}

sub setRow {
    my $self=shift;
    $self->{ROW} = shift;
}

sub getRow{
    my $self=shift;
    return $self->{ROW};
}

sub setColumn{
    my $self=shift;
    $self->{COLUMN} = shift;
}

sub getColumn{
    my $self=shift;
    return $self->{COLUMN};
}

sub setSquare{
    my $self=shift;
    $self->{SQUARE} = shift;
}

sub getSquare{
    my $self=shift;
    return $self->{SQUARE};
}

sub couldBe{
    my $self=shift;
    my $value=shift;
    return $self->{POSSIBLES}{$value};
}

sub notPossible {
  my $self = shift;
  #no point in checking if we already have a value
  if (defined $self->{VALUE}) {
      return 0;
  }
  my (@impossible_values) = @_;

  #remove impossible values
  foreach my $value (@impossible_values){
      if (exists $self->{POSSIBLES}{$value}){
	  #print "deleting $value\n";
	  delete $self->{POSSIBLES}{$value};
      }
  }

  #if there is only one left, we win
  my @possible_values = keys(%{$self->{POSSIBLES}});
  if ($#possible_values == 0){
    $self->setValue($possible_values[0]);
  }
  return $#possible_values;
}

sub toStr {
    my $self = shift;
    if (defined $self->{VALUE}){
	return sprintf ("%X", ($self->{VALUE}));
    }else {
	my @possibles = map {sprintf "%X", $_} sort { $a <=> $b} keys (%{$self->{POSSIBLES}});	
	return "(". join (':', @possibles) . ")";
    }
}


1;
