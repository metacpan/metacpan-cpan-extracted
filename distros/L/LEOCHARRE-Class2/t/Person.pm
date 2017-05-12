package Person;
use strict;
use LEOCHARRE::Class2;


__PACKAGE__->make_constructor();
__PACKAGE__->make_accessor_setget( 
   'name', 
   'name_last',
   [ 'inventory' => [qw(various defaults here)] ],
   [ age => 19 ], 
   { speed => 348, pants => 27, hang => undef }, 
);

__PACKAGE__->make_accessor_setget({ 
   houses => [],
   blocks => {},
   });


sub houses_add {
   my $self = shift;
   my $house = shift;

   #my $houses = $self->houses;
   #push @$houses, $house;
   push @{$self->{houses}}, $house;

   return $self->houses_count;
}

sub houses_count {
   my $self = shift;
   return ( scalar @{ $self->houses } );
}


1;

