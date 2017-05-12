package MealMaster::Ingredient;
use strict;
use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_accessors(qw(quantity measure product));

1;

__END__

=head1 NAME

MealMaster::Ingredient - Represent a MealMaster ingredient

=head1 SYNOPSIS

    print "Ingredients:\n";
    foreach my $i (@{$r->ingredients}) {
      print "  " . $i->quantity .
             " " . $i->measure  .
             " " . $i->product . 
             "\n";
    }

=head1 DESCRIPTION

L<MealMaster::Ingredient> represents an ingredient in a MealMaster recipe.

=head1 METHODS

=head2 measure

Returns the measurement unit of the ingredient:

  print $i->measure . "\n";
  
=head2 product

Returns the ingredient name:

  print $i->product . "\n";
  
=head2 quantity

Returns the quantity of measures needed:

  print $i->quantity . "\n";

=head1 SEE ALSO

L<MealMaster>, L<MealMaster::Recipe>

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
