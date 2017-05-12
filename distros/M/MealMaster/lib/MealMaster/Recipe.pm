package MealMaster::Recipe;
use strict;
use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_accessors(qw(title categories yield ingredients directions));

1;

=head1 NAME

MealMaster::Recipe - Represent a MealMaster Recipe

=head1 SYNOPSIS

  foreach my $r (@recipes) {
    print "Title: " . $r->title . "\n";
    print "Categories: " . join(", ", sort @{$r->categories}) . "\n";
    print "Yield: " . $r->yield . "\n";
    print "Directions: " . $r->directions . "\n";
    print "Ingredients:\n";
    foreach my $i (@{$r->ingredients}) {
      print "  " . $i->quantity .
             " " . $i->measure  .
             " " . $i->product . 
             "\n";
    }

=head1 DESCRIPTION

L<MealMaster::Recipe> represents a MealMaster recipe.

=head1 METHODS

=head2 categories

Returns an array reference of the categories that the recipe is filed
under:

    print "Categories: " . join(", ", sort @{$r->categories}) . "\n";

=head2 directions

Returns the directions for making the recipe:

    print "Directions: " . $r->directions . "\n";

=head2 ingredients

Returns a list of ingredients for making the recipe:

    print "Ingredients:\n";
    foreach my $i (@{$r->ingredients}) {
      print "  " . $i->quantity .
             " " . $i->measure  .
             " " . $i->product . 
             "\n";
    }

=head2 title

Returns the title of the recipe:

    print "Title: " . $r->title . "\n";

Returns the yield of the recipe:

    print "Yield: " . $r->yield . "\n";
 
=head1 SEE ALSO

L<MealMaster>, L<MealMaster::Ingredient>

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
