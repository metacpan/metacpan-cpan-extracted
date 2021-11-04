package GFX::Enhancer::AlphaVector;

use parent 'Vector';

sub new {
  my ($class, $bitstring) = @_;
  my $self = $class->SUPER::new($bitstring);
  
}

### diminish

sub lessen_channel {
  my ($self, $less) = @_;

  $self->{bitstring} >>= $less;
  $self->{bitstring} %= 256;
}

sub substract_from_channel {
  my ($self, $bitsvalue) = @_;

  $self->{bitstring} -= $bitsvalue;
  $self->{bitstring} %= 256;
}

### enlarge

sub greater_channel {
  my ($self, $greater) = @_;

  $self->{bitstring} <<= $greater;
  $self->{bitstring} %= 256;
}

sub add_to_channel {
  my ($self, $bitsvalue) = @_;

  $self->{bitstring} += $bitsvalue;
  $self->{bitstring} %= 256;
}

1;
