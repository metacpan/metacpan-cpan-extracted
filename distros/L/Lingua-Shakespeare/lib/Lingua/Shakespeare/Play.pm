package Lingua::Shakespeare::Play;

use Carp;
use strict;

use Lingua::Shakespeare::Character;

sub new {
  bless {}
}

sub declare_character {
  my $self = shift;
  my $name = shift;
  carp "Duplicate declaration of $name"
    if $self->{character}{lc $name};

  $self->{character}{lc $name} = Lingua::Shakespeare::Character->new($name);
}

sub enter_scene {
  my $self = shift;
  my $char = shift;

  carp $char->name . " is already on stage"
    if $self->{stage}{$char};

  $self->{stage}{$char} = $char;
}

sub activate_character {
  my $self = shift;
  my $char = shift;

  croak $char->name . " is not on stage"
    unless $self->{stage}{$char};

  $self->{active} = $char;
}

sub first_person {
  my $self = shift;
  $self->{active};
}

sub second_person {
  my $self = shift;

  my $stage = $self->{stage} ||= {};
  my $on_stage = keys %$stage;
  my $active = $self->{active};

  return (grep { $_ != $active } values %$stage)[0]
    if $on_stage == 2 and $active;

  croak "Nobody on stage"
    unless $on_stage;

  croak "Only " . (values %$stage)[0]->name . " is on stage"
    if $on_stage == 1;

  croak "More than two characters on stage"
    if $on_stage > 2;

  croak "No active character";
}

sub exit_scene {
  my $self = shift;
  my $char = shift;

  carp $char->name . " is not on stage"
    unless delete $self->{stage}{$char};

  if (my $active = $self->{active}) {
    delete $self->{active} if $active == $char;
  }
}

sub int_twice {
  my $self = shift;
  my $value = shift;
  2 * $value;
}

sub int_square {
  my $self = shift;
  my $value = shift;
  $value * $value;
}

sub int_sqrt {
  my $self = shift;
  my $value = shift;
  sqrt($value);
}

sub int_cube {
  my $self = shift;
  my $value = shift;
  $value * $value * $value;
}

sub int_add {
  my $self = shift;
  $_[0] + $_[1];
}

sub int_mod {
  my $self = shift;
  $_[0] % $_[1];
}

sub int_sub {
  my $self = shift;
  $_[0] - $_[1];
}

sub int_mul {
  my $self = shift;
  $_[0] * $_[1];
}

sub int_div {
  my $self = shift;
  int($_[0] / $_[1]);
}

sub int_factorial {
  my $self = shift;
  my $value = shift;

  if ($value == 0) {
    $value = 1;
  }
  for (my $i = $value - 1; $i > 1; $i--) {
    $value *= $i;
  }

  $value;
}



sub exit_scene_all {
  my $self = shift;
  $self->{stage} = {};
  delete $self->{active};
}


1;

