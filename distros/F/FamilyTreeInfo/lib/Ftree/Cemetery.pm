package Ftree::Cemetery;

use strict;
use warnings;

use version; our $VERSION = qv('2.3.41');

use Ftree::Place;
use Params::Validate qw(:all);

use base 'Ftree::Place';
sub new {
    my $type = shift;
    my $self = $type->SUPER::new(@_);
    $self->{cemetery} = $_[2];
    return $self;
 }
 
 sub toString {
 	  my ( $self) = validate_pos(@_, {type => HASHREF});
 	  my $string = $self->SUPER::toString();
      return defined $self->{cemetery} ? "$string, $self->{cemetery}" : $string;
 }

 1;
