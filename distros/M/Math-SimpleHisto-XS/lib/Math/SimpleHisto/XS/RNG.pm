package Math::SimpleHisto::XS::RNG;
use strict;
use warnings;

our $VERSION = '0.01';

our $Gen = __PACKAGE__->new(_seed());

sub _seed {
  my $x;
  my @refs = (\$x, [], {}, sub {}); # yeah, random is different :(
  my @ints = (time, $$);
  foreach my $ref (@refs) {
    $ref = "$ref";
    $ref =~ s/^\w+\(0x(\w+)\)$/$1/ or next;
    $ref = unpack("h*", $ref);
    $ref = $ref % 2**31;
    push @ints, $ref;
  }
  return @ints;
}


sub new {
  my $class = shift;
  if (@_ == 1) {
    return setup(shift); # XS
  }
  else {
    return setup_array(@_); # XS
  }
}

sub rand {
  my ($self, $x) = @_;
  if (ref $self) {
    return ($x || 1) * $self->genrand();
  }
  else {
    $x = $self;
    $Gen = __PACKAGE__->new(_seed()) if not defined $Gen;
    return ($x || 1) * $Gen->genrand();
  }
}

1;
