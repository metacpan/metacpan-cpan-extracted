package Ftree::Place;

use strict;
use warnings;

use version; our $VERSION = qv('2.3.41');

use Params::Validate qw(:all);

sub new {
  my ( $classname, $country, $city) = @_;
  my $self = {
     country => $country,
     city => $city,     
  };
  return bless $self, $classname;
}

 sub toString {
 	  my ( $self) = validate_pos(@_, HASHREF);
 	  if(defined $self->{city}) {
 	  	return defined $self->{city} ? "$self->{city} ($self->{country})" : $self->{country}; 
 	  }
 	  else {
 	  	return defined $self->{country} ? $self->{country} : "";
 	  }
 }

1;