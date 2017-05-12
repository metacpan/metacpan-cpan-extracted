package Test;
use base 'LEOCHARRE::Database';
use strict;
use warnings;

sub new {
   my ($class, $self ) = @_;
   bless $self, $class;
   return $self;
}

1;

