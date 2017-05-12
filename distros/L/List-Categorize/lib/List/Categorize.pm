package List::Categorize;
#
# ABSTRACT: Categorize list items into a hash of named sublists.
#
# See documentation after __END__ below.
# 

use strict;
use warnings;

## Module Interface

use base 'Exporter';

our $VERSION = '0.03';
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
# Usage:    %hash = categorize {BLOCK} @LIST
# Returns:  a hash of lists
#
# Creates a hash by running a subroutine for each element in a list. The
# subroutine returns a hash key (the "category") for the current
# element. (If the subroutine returns undef for a list element, that
# element is not placed in the resulting hash.)
#
# The resulting hash contains a key for each category, and each key
# refers to a list of the elements that correspond to that category.
# 
{
    # Parameters
    #
    my $coderef = shift;

    # @_ is used directly, in the loop below.

    # This is the hash of lists that will be returned to the caller.
    #
    my %sublists = ();

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

        # Execute the categorizer subroutine to determine the category
        # for this element.
        #
        my $category = $coderef->();

        # If a category was returned, use it as a key in the %sublists
        # hash, and add the current element to the list referenced by
        # that key.
        #
        # If the categorizer didn't return a value (or returned undef),
        # then leave this element out of %sublists entirely.
        #
        if (defined $category)
        {
            push @{ $sublists{ $category } }, $_;
        }
    }

    return %sublists;
}


1;

__END__

=head1 NAME

List::Categorize - Categorize list items into a hash of named sublists

=head1 VERSION

This documentation describes List::Categorize version 0.01.

=head1 SYNOPSIS

    use List::Categorize qw(categorize);

    my %odds_and_evens = categorize { $_ % 2 ? 'ODD' : 'EVEN' } (1..9);

    # %odds_and_evens now contains
    # ( ODD => [ 1, 3, 5, 7, 9 ], EVEN => [ 2, 4, 6, 8 ] )

    my %capitalized = categorize {

        # Transform the element before placing it in the hash.
        $_ = ucfirst $_;

        # Use the first letter of the element as the category.
        substr($_, 0, 1);

    } qw( apple banana antelope bear canteloupe coyote );

    # %capitalized now contains
    # (
    #   A => [ 'Apple', 'Antelope' ],
    #   B => [ 'Banana', 'Bear' ],
    #   C => [ 'Canteloupe', 'Coyote' ]
    # )

=head1 DESCRIPTION

A simple module that creates a hash by applying a specified rule to
each element of a provided list.

=head1 EXPORT

Nothing by default.

=head1 SUBROUTINES

=head2 categorize BLOCK LIST

    my %hash = categorize { $_ > 10 ? 'Big' : 'Little' } @list;

C<categorize> creates a hash by running BLOCK for each element in LIST.
The block returns a hash key (the "category") for the current
element. (If it returns C<undef> for a list element, that element is
not placed in the resulting hash.)

The resulting hash contains a key for each category, and each key refers to a
list of the elements that correspond to that category.

Within the block, $_ refers to the current list element. Elements can be
modified before they're placed in the target hash by modifying the $_
variable:

    my %hash = categorize { $_ = uc $_; 'List' } qw( one two three );

    # %hash now contains ( List => [ 'ONE', 'TWO', 'THREE' ] )

NOTE: The categorizer should return a string, or C<undef>. Other values
are reserved for future use, and may cause unpredictable results in the
current version.

=head1 SEE ALSO

L<List::Part>

=head1 AUTHOR

Bill Odom, C<< <wnodom at cpan.org> >>

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

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=List-Categorize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/List-Categorize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/List-Categorize>

=item * Search CPAN

L<http://search.cpan.org/dist/List-Categorize/>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Bill Odom.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses at L<http://www.perlfoundation.org/artistic_license_1_0>,
and L<http://www.gnu.org/licenses/gpl-2.0.html>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut

# end List::Categorize
