package List::Categorize::Multi;
use strict;
use warnings;

use Exporter qw/import/;
use Carp qw/croak/;

our $VERSION = '0.02';
our @EXPORT  = qw(categorize);

sub categorize (&@) {
  my $coderef = shift; # the rest of @_ is the list of elements to categorize

  my %tree = ();

  for my $element (@_) {
    # localize $_ and call the coderef
    local $_       = $element;
    my @categories = $coderef->(); # expected: list of categorizing scalars

    # loop over categories, using them to walk through/create the tree
    my $node = \%tree;
  CATEGORY:
    while (@categories) {
      my $categ = shift @categories;

      # if an undef is encountered, this element will be ignored
      defined $categ or last;

      if (@categories) {
        # create or retrieve an intermediate node
        $node = $node->{$categ} ||= {};
        ref $node ne 'ARRAY'
          or croak "inconsistent use of category '$categ'";
      }
      else {
        # add the element to a leaf
        my $ref = ref $node->{$categ} || '';
        $ref ne 'HASH'
          or croak "inconsistent use of category '$categ'";
        push @{$node->{$categ}}, $_;
      }
    }
  }

  return %tree;
}

1;

__END__

=head1 NAME

List::Categorize::Multi - A clone of List-Categorize with support for multiple subcategories.

=head1 SYNOPSIS

  use List::Categorize::Multi qw(categorize);

  my %odds_and_evens = categorize { $_ % 2 ? 'ODD' : 'EVEN' } (1..9);

  # %odds_and_evens now contains
  # ( ODD => [ 1, 3, 5, 7, 9 ], EVEN => [ 2, 4, 6, 8 ] )

  my %capitalized = categorize {

      # Transform the element before placing it in the hash.
      $_ = ucfirst $_;

      # Use the first letter of the element as the first-level category,
      # then the first 2 letters as a second-level category
      substr($_, 0, 1), substr($_, 0, 2);

  } qw( apple banana antelope bear canteloupe coyote ananas );

  # %capitalized now contains
  # (
  #   A => { An => ['Antelope', 'Ananas'], Ap => ['Apple'], },
  #   B => { Ba => ['Banana'],             Be => ['Bear'],  },
  #   C => { Ca => ['Canteloupe'],         Co => ['Coyote'] },
  # )

=head1 DESCRIPTION

This module is a clone of L<List::Categorize>, with the same
application programming interface, but with one additional
feature : the ability to create multi-level categories.
The result is a tree, labeled by categories,
where intermediate nodes contain references to subtrees,
and leaf nodes contain arrayrefs of elements belonging
to that category.

=head1 EXPORTS

=head2 categorize

  my %tree = categorize { ... } @list;

This is the single exported function, and is exported by default.

The first argument is a coderef or a block, which will be applied to
each element in C<@list>, while aliasing C<$_> to the current list
element (C<$_> can even be modified within the block).

The block should return a list of "categories" for the current
element, i.e a list of scalar values corresponding to the sequence
of subtrees under which this element will be placed.

If the block always returns one single value, then the module behaves
exactly like L<List::Categorize>. If it returns an empty list,
or a list containing an C<undef>,
the corresponding element is not placed in the resulting tree
(again just like L<List::Categorize>).

The resulting tree contains a key for each top-level category.
Values are either references to subtrees, or references
to arrayrefs of elements (depending on the depth of the categorization).

=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>,
with ideas and code copied from
Bill Odom, C<< <wnodom at cpan.org> >>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::Categorize

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=List-Categorize-Multi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/List-Categorize-Multi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/List-Categorize-Multi>

=item * Search MetaCPAN

L<https://metacpan.org/module/List::Categorize::Multi>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013 Laurent Dami

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut


