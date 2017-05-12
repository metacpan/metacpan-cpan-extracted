## no critic (RCS,prototypes)

package List::BinarySearch::PP;

use 5.006000;

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA    = qw(Exporter);    ## no critic (ISA)
our @EXPORT = qw( binsearch binsearch_pos ); ## no critic (export)


our $VERSION = '0.25';
# $VERSION = eval $VERSION;  ## no critic (eval)



#---------------------------------------------
# Use a callback for comparisons.

sub binsearch (&$\@) {
    my ( $code, $target, $aref ) = @_;
    my $min = 0;
    my $max = $#{$aref};
    my $caller = caller();
    while ( $max > $min ) {
        my $mid = int( ( $max - $min ) / 2 + $min );
        no strict 'refs'; ## no critic(strict)
        local ( ${"${caller}::a"}, ${"${caller}::b"} )
          = ( $target, $aref->[$mid] );
        if ( $code->( $target, $aref->[$mid] ) > 0 ) {
            $min = $mid + 1;
        }
        else {
            $max = $mid;
        }
    }
    {
      no strict 'refs'; ## no critic(strict)
      local ( ${"${caller}::a"}, ${"${caller}::b"} )
        = ( $target, $aref->[$min] );
      return $min if $code->( $target, $aref->[$min] ) == 0;
    }
    return;    # Undef in scalar context, empty list in list context.
}


#------------------------------------------------------
# Identical to binsearch, but upon match-failure returns best insert
# position for $target.


sub binsearch_pos (&$\@) {
    my ( $comp, $target, $aref ) = @_;
    my ( $low, $high ) = ( 0, scalar @{$aref} );
    my $caller = caller();
    while ( $low < $high ) {
        my $cur = int( ( $high - $low ) / 2 + $low );
        no strict 'refs';  ## no critic(strict)
        local ( ${"${caller}::a"}, ${"${caller}::b"} )
          = ( $target, $aref->[$cur] );                            # Future use.
        if ( $comp->( $target, $aref->[$cur] ) > 0 ) {
            $low = $cur + 1;
        }
        else {
            $high = $cur;
        }
    }
    return $low;
}


1;

__END__

=head1 NAME

List::BinarySearch::PP - Pure-Perl Binary Search functions.


=head1 SYNOPSIS

This module is a plugin for List::BinarySearch providing a graceful fallback to
a pure-Perl binary search implementation in case the optional (but default)
List::BinarySearch::XS dependency cannot be built on a target system.  It is
provided by the L<List::BinarySearch> distribution.

Examples:


    use List::BinarySearch qw( binsearch  binsearch_pos  binsearch_range );

    # Find the lowest index of a matching element.
    $index = binsearch {$a <=> $b} 300, @{[ 100, 200, 300, 400 ]};
    $index = binsearch {$a cmp $b} 'Mozart', @{[ qw/ Bach Brahms Mozart / ]};
    $index = binsearch {$a <=> $b} 42, @{[ 10, 20, 30 ]}      # not found: undef

    # Find the lowest index of a matching element, or best insert point.
    $index = binsearch_pos {$a cmp $b} 'Chopin', @{[ qw/ Bach Brahms Mozart/ ]};  # Insert at [2].
    $index = binsearch_pos {$a <=> $b} 60, @{[ 10, 20, 30, 40, 50, 70 ]}; # Insert at [5].
    $index = binsearch_pos {$a <=> $b} 20, @{[ 10, 20, 30 ]}; # Matched at [1]


=head1 DESCRIPTION

This module is intended to be used by L<List::BinarySearch>, and shouldn't need
to be used directly in user-code.

This module provides pure-Perl implementations of the C<binsearch> and
C<binsearch_pos> functions for use by L<List::BinarySearch>.  Please refer to
the documentation for L<List::BinarySearch> for a full description of those
functions.  What follows is a very brief overview.

These pure-Perl functions will be overridden by XS code when used via
L<List::BinarySearch> if L<List::BinarySearch::XS> is installed (the default,
and recommended). The pure-Perl functions exist as a gracefull downgrade in case
users aren't able to use XS modules.


=head1 EXPORT

List::BinarySearch::PP exports by default C<binsearch> and C<binsearch_pos>.

=head1 SUBROUTINES/METHODS

=head2 binsearch CODE NEEDLE ARRAY_HAYSTACK

    $first_found_ix = binsearch { $a cmp $b } $needle, @haystack;

Uses the supplied code block as a comparator to search for C<$needle> within
C<@haystack>.  If C<$needle> is found, return value will be the lowest index of
a matching element, or C<undef> if the needle isn't found.

=head2 binsearch_pos CODE NEEDLE ARRAY_HAYSTACK

    $first_found_ix = binsearch_pos { $a cmp $b } $needle, @haystack;

Uses the supplied code block as a comparator to search for C<$needle> within
C<@haystack>. If C<$needle> is found, return value will be the lowest index of
a matching element, or the index of the best insertion point for the needle if
it isn't found.


=head1 CONFIGURATION AND ENVIRONMENT

Perl 5.8 or newer required.  This module is part of the L<List::BinarySearch>
distribution, and is intended for use by the C<List::BinarySearch> module.
Though the user interface is unlikely to change, it shouldn't be directly used
by code outside of this distribution.


=head1 DEPENDENCIES

Perl 5.8.


=head1 INCOMPATIBILITIES

Perl versions prior to 5.8 aren't supported by this distribution.  See the
POD from L<List::BinarySearch> for a more detailed explanation.


=head1 AUTHOR

David Oswald, C<< <davido at cpan.org> >>

If the documentation fails to answer your question, or if you have a comment
or suggestion, send me an email.


=head1 DIAGNOSTICS


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
L<https://github.com/daoswald/List-BinarySearch/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::BinarySearch

This module is maintained in a public repo at Github.  You may look for
information at:

=over 4

=item * Github: Development is hosted on Github at:

L<http://www.github.com/daoswald/List-BinarySearch>

=item * GitHub Issue tracker (report bugs here)

L<https://github.com/daoswald/List-BinarySearch/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/List-BinarySearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/List-BinarySearch>

=item * Search CPAN

L<http://search.cpan.org/dist/List-BinarySearch/>

=back


=head1 ACKNOWLEDGEMENTS

L<Mastering Algorithms with Perl|http://shop.oreilly.com/product/9781565923980.do>,
from L<O'Reilly|http://www.oreilly.com>: much of the code behind the positional
search.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
