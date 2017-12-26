package List::Categorize;
#
# ABSTRACT: Categorize list items into a tree of named sublists.
#
# See documentation after __END__ below.
# 

use strict;
use warnings;
use 5.006;

## Module Interface

use base 'Exporter';
use Carp qw/croak/;

our $VERSION = '0.04';
our @EXPORT = qw();
our @EXPORT_OK = qw(
    categorize
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK
);


## Subroutines

sub categorize (&@)
#
# Usage:    %tree = categorize {BLOCK} @LIST
# Returns:  a tree of lists
#
# Creates a tree by running a subroutine for each element in a
# list. That subroutine should return a list of hash keys (the
# "categories") for the current element, each key in the list
# corresponding to the next depth level within the tree. If the
# subroutine returns undef for a list element, that element is not
# placed in the resulting tree.
#
# The resulting tree contains a key for each first-level category, and
# each key refers to a sub-tree for the next-level category,
# etc. until reaching a leaf, which contains a list of the elements
# that correspond to that sequence of categories. If there is only one
# level of categories, the structure is just a hashref of lists of
# elements.
#
{
    # Parameters
    #
    my $coderef = shift;

    # @_ is used directly, in the loop below.

    # This is the tree that will be returned to the caller.
    #
    my %tree = ();

    # Iterate over the provided list, categorizing
    # each element.
    #
    for my $element (@_)
    {
        # Localize $_, then copy the current element into it, so the
        # categorizer subroutine can refer to $_ (in the same way as
        # map, grep, and sort do).
        # 
        # Copying the element keeps it from acting as an alias into the
        # @_ list, so the categorizer can modify $_ without damaging the
        # source list.
        # 
        local $_ = $element;

        # Execute the categorizer subroutine to determine the categories
        # for this element.
        #
        my @categories = $coderef->();

        # If categories were returned, use them as keys in %tree,
        # and add the current element to the list referenced by
        # those keys.
        #
        # If the categorizer didn't return a value (or returned undef),
        # then leave this element out of %tree entirely.
        #

        my $node = \%tree;
      CATEGORY:
        while (@categories) {
            my $categ = shift @categories;

            # if an undef is encountered, this element will be ignored
            defined $categ or last CATEGORY;

            if (@categories) {
                # other keys remaining, so create or retrieve an intermediate node
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

List::Categorize - Categorize list items into a tree of named sublists

=head1 VERSION

This documentation describes List::Categorize version 0.04.

=head1 SYNOPSIS

    use List::Categorize qw(categorize);

    my %odds_and_evens = categorize { $_ % 2 ? 'ODD' : 'EVEN' } (1..9);

    # %odds_and_evens now contains
    # ( ODD => [ 1, 3, 5, 7, 9 ], EVEN => [ 2, 4, 6, 8 ] )

    my %capitalized = categorize {

        # Transform the element before placing it in the tree.
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

A simple module that creates a tree by applying a specified rule to
each element of a provided list.

=head1 EXPORT

Nothing by default.

=head1 SUBROUTINES

=head2 categorize BLOCK LIST

    my %tree = categorize { $_ > 10 ? 'Big' : 'Little' } @list;

C<categorize> creates a tree by running BLOCK for each element in
LIST.  The block should return a list of "categories" for the current
element, i.e a list of scalar values corresponding to the sequence of
subtrees under which this element will be placed.  If the block
returns an empty list, or a list containing an C<undef>, the
corresponding element is not placed in the resulting tree.

The resulting tree contains a key for each top-level category.
Values are either references to subtrees, or references
to arrayrefs of elements (depending on the depth of the categorization).

Within the block, $_ refers to the current list element. Elements can be
modified before they're placed in the target tree by modifying the $_
variable:

    my %tree = categorize { $_ = uc $_; 'List' } qw( one two three );

    # %tree now contains ( List => [ 'ONE', 'TWO', 'THREE' ] )

NOTE: The categorizer should return a list of strings, or C<undef>. Other values
are reserved for future use, and may cause unpredictable results in the
current version. When using multi-level categorization, the categorizer
should always return the same number of keys.


=head1 SEE ALSO

L<List::MoreUtils/part>

Previous versions of this module only handled one-level categorization,
while multi-level categorization was implemented in
L<List::Categorize::Multi>. Now both modules have been merged
into L<List::Categorize>, therefore L<List::Categorize::Multi> is deprecated.


=head1 AUTHOR

Bill Odom, C<< <wnodom at cpan.org> >> (original author),
Laurent Dami, C<< <dami at cpan.org> >> (added the multi-level categorization)


=head1 BUGS

None known.

Please report any bugs or feature requests to
C<bug-list-categorize at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=List-Categorize>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::Categorize

You can also look for information at:

=over 4

=item RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=List-Categorize>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/List-Categorize>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/List-Categorize>

=item Search MetaCPAN

L<https://metacpan.org/module/List::Categorize>

=item Github repository

L<https://github.com/damil/List-Categorize>


=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Bill Odom, 2017 Laurent Dami.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses at L<http://www.perlfoundation.org/artistic_license_2_0>,
and L<http://www.gnu.org/licenses/gpl-2.0.html>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut

# end List::Categorize
