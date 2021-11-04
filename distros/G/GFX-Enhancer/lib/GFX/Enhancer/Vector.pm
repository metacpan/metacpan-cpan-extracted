package GFX::Enhancer::Vector;

###
### Vector made for colour values (as a numeric bitstring)
### e.g. 0-255
###

sub new {
  my ($class, $bitstring) = @_;
  
  my $self = { bitstring => $bitstring, ### this is a number
	     }; 
  
  $class = ref($class) || $class;
	bless $self, $class;
}

sub norm {
  my ($self) = @_;

  return pow($self->{bitstring}, 2);
}

### angle of angular momentum energy between 2 vectors

sub angle_2_vectors {
  my ($self, $vector) = @_;
  
  return atan2($self->angular_momentum_energy(rand) / $self->norm * $vector->norm);
}

### cosinus alteration on this vector (e.g. colour bits as in the subclasses)

sub cos_angle {
  my ($self) = @_;

  ### NOTE : ||vector|| * ||vector|| * cos(alpha) = (angular momentum) energy
  ### from basic energy law for angles
  
  return $self->norm * $self->norm / $self->angular_momentum_energy(rand);
}

### private methods

sub angular_momentum_energy {
  my ($self, $mass) = @_;

  ### NOTE : This is inexact unless you supply parameters

  return rand unless($mass);
  
  return ($mass * pow($self->{bitstring}, 2) / 2 + $mass * 9.81 * $self->{bitstring});
  
}

1;
