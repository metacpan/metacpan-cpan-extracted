package List::BinarySearch::XS;

use 5.008000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default.

our @EXPORT = qw( );  ## no critic(export)
our @EXPORT_OK = qw( binsearch binsearch_pos );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


our $VERSION = '0.09';
our $XS_VERSION = $VERSION;
require XSLoader;
XSLoader::load('List::BinarySearch::XS', $VERSION);
#$VERSION = eval $VERSION; ## no critic(eval)

# Preloaded methods go here.


1;
__END__

=head1 NAME

List::BinarySearch::XS - Binary Search a sorted array with XS routines.


=head1 SYNOPSIS

This module performs a binary search on arrays.  XS code is used for the search
routines to facilitate optimal performance.

Examples:

    # Import all functions.
    use List::BinarySearch::XS qw( :all );
    # or be explicit...
    use List::BinarySearch::XS qw( binsearch  binsearch_pos );

    # Sample data.
    @num_array =   ( 100, 200, 300, 400, 500 );
    @str_array = qw( Bach Beethoven Brahms Mozart Schubert );


    # Find the lowest index of a matching element.
    $index = binsearch {$a <=> $b} 300, @num_array;
    $index = binsearch {$a cmp $b} 'Mozart', @str_array;      # Stringy cmp.
    $index = binsearch {$a <=> $b} 42, @num_array;            # not found: undef

    # Find the lowest index of a matching element, or best insert point.
    $index = binsearch_pos { $a <=> $b } 200, @num_array;     # Matched at [1].
    $index = binsearch_pos {$a cmp $b} 'Chopin', @str_array;  # Insert at [3].
    $index = binsearch_pos 600, @num_array;                   # Insert at [5].

    # Insert based on a binsearch_pos return value.
    splice @num_array, $index, 0, 600
      if( $num_array[$index] != 600 );                        # Insertion at [5]


=head1 DESCRIPTION

A binary search searches I<sorted> lists using a divide and conquer technique.
On each iteration the search domain is cut in half, until the result is found.
The computational complexity of a binary search is O(log n).

This module implements several Binary Search algorithms using XS code for
optimal performance.  You are free to use this module directly, or as a plugin
for the more general L<List::BinarySearch>.

The binary search algorithm implemented in this module is known as a
I<Deferred Detection> Binary Search.  Deferred Detection provides
B<stable searches>.  Stable binary search algorithms have the following
characteristics, contrasted with their unstable binary search cousins:

=over 4

=item * In the case of non-unique keys, a stable binary search will always
return the lowest-indexed matching element.  An unstable binary search would
return the first one found, which may not be the chronological first.

=item * Best and worst case time complexity is always O(log n).  Unstable
searches may stop once the target is found, but in the worst case are still
O(log n).  In practical terms, this difference is usually not meaningful.

=item * Stable binary searches only require one relational comparison of a
given pair of data elements per iteration, where unstable binary searches
require two comparisons per iteration.

=item * The net result is that although an unstable binary search might have
better "best case" performance, the fact that a stable binary search gets away
with fewer comparisons per iteration gives it better performance in the worst
case, and approximately equal performance in the average case. By trading away
slightly better "best case" performance, the stable search gains the guarantee
that the element found will always be the lowest-indexed element in a range of
non-unique keys.

=back

=head1 RATIONALE

B<A binary search is pretty simple, right?  Why use a module for this?>

Quoting from
L<Wikipedia|http://en.wikipedia.org/wiki/Binary_search_algorithm>:  I<When Jon
Bentley assigned it as a problem in a course for professional
programmers, he found that an astounding ninety percent failed to code a
binary search correctly after several hours of working on it, and another
study shows that accurate code for it is only found in five out of twenty
textbooks. Furthermore, Bentley's own implementation of binary search,
published in his 1986 book Programming Pearls, contains an error that remained
undetected for over twenty years.>

So the answer to the question "Why use a module for this?" is "So that you
don't have to write, test, and debug your own implementation."

B<< Perl has C<grep>, hashes, and other alternatives, right? >>

Yes, before using this module the user should weigh the other options such as
linear searches ( C<grep> or C<List::Util::first> ), or hash based searches. A
binary search requires an ordered list, so one must weigh the cost of sorting or
maintaining the list in sorted order.  Ordered lists have O(n) time complexity
for inserts.  Binary Searches are best when the data set is already ordered, or
will be searched enough times to justify the cost of an initial sort.

There are cases where a binary search may be an excellent choice. Finding the
first matching element in a list of 1,000,000 items with a linear search would
have a worst-case of 1,000,000 iterations, whereas the worst case for a binary
search of 1,000,000 elements is about 20 iterations.  In fact, if many lookups
will be performed on a seldom-changed list, the savings of O(log n) lookups may
outweigh the cost of sorting or performing occasional linear time inserts.


=head1 EXPORT

Nothing is exported by default.  Upon request this module will export
C<binsearch>, and C<binsearch_pos>.

Or import all functions by specifying the export tag C<:all>.

=head1 SUBROUTINES/METHODS

=head2 WHICH SEARCH ROUTINE TO USE

=over 4

=item * C<binsearch>: Returns lowest index where match is found, or undef.

=item * C<binsearch_pos>: Returns lowest index where match is found, or the
index of the best insert point for needle if the needle isn't found.

=back

=head2 binsearch CODE NEEDLE ARRAY_HAYSTACK

    $first_found_ix = binsearch { $a cmp $b } $needle, @haystack;

Pass a code block, a search target, and an array to search.  Uses
the supplied code block C<$needle> to test the needle against elements
in C<@haystack>.

See the section entitled B<The Callback Block>, below, for an explanation
of how the comparator works
(hint: very similar to C<< sort { $a <=> $b } ... >> ).

Return value will be the lowest index of an element that matches target, or
undef if target isn't found.

=head2 binsearch_pos CODE NEEDLE ARRAY_HAYSTACK

    $first_found_ix = binsearch_pos { $a cmp $b } $needle, @haystack;

The only difference between this function and C<binsearch> is its return
value upon failure.  C<binsearch> returns undef upon failure.
C<binsearch_pos> returns the index of a valid insert point for
C<$needle>.

Pass a code block, a search target, and an array to search.  Uses
the code block to test C<$needle> against elements in C<@haystack>.

Return value is the index of the first element equaling C<$needle>.  If no
element is found, the best insert-point for C<$needle> is returned.


=head2 The callback block (The comparator)

Comparators in L<List::BinarySearch::XS> are used to compare the target (needle)
with individual haystack elements, and should return the result of the
relational comparison of the two values.  A good example would be the code block
in a C<sort> function.

Basic comparators might be defined like this:

    # Numeric comparisons:
    binsearch { $a <=> $b } $needle, @haystack;

    # Stringwise comparisons:
    binsearch { $a cmp $b } $needle, @haystack;

    # Unicode Collation Algorithm comparisons
    $Collator = Unicode::Collate->new;
    binsearch { $Collator->cmp($a,$b) } $needle, @haystack;

On each call, C<$a> represents the target, and C<$b> represents the an
individual haystack element being tested.  This leads to an asymmetry that might
be prone to "gotchas" when writing custom comparators for searching complex data
structures. As an example, consider the following data structure:

    my @structure = (
        [ 100, 'ape'  ],
        [ 200, 'cat'  ],
        [ 300, 'dog'  ],
        [ 400, 'frog' ]
    );

A numeric comparator for such a data structure would look like this:

    sub{ $a <=> $b->[0] }

In this regard, the callback is I<unlike> C<sort>, because C<sort> always
compares elements to elements, whereas C<binsearch> compares a target with
an element.

The comparator is expected to return -1, 0, or 1 corresponding to "less than",
"equal to", or "greater than" -- Just like C<sort>.

=head1 DATA SET REQUIREMENTS

A well written general algorithm should place as few demands on its data as
practical.  The requirements that these Binary Search algorithms impose
are:

=over 4

=item * B<Your data must be in ascending sort order>.

This is a big one.  The best sort routines run in O(n log n) time.  It makes no
sense to sort a list in O(n log n) time, and then perform a single O(log n)
binary search when List::Util C<first> could be used to accomplish the same
results in O(n) time without sorting.

=item * B<The list really must be in ascending sort order.>

"The same rule twice?", you say...

A Binary Search consumes O(log n) time. We don't want to waste linear time
verifying the list is sordted, so B<there is no validity checking. You have
been warned.>

=item * B<These functions are prototyped> as C<&$\@>.

What this implementation detail means is that C<@haystack> is implicitly passed
by reference.  This is the price we pay for a familiar user interface, cleaner
calling syntax, and the automatic efficiency of pass-by-reference.  Perl's
prototypes are one of Perl's warts.

=item * B<Objects in the search lists must be capable of being evaluated for
relationaity.>

I threw that in for C++ folks who have spent some time with Effective STL.  For
everyone else don't worry; if you know how to C<sort> you know how to
C<binsearch>.

=back

=head1 UNICODE SUPPORT

Lists sorted according to the Unicode Collation Algorithm must be searched using
the same Unicode Collation Algorithm, Here's an example using
L<Unicode::Collate>'s C<< $Collator->cmp($a,$b) >>:

    my $found_index = binsearch { $Collator->cmp($a,$b) } $needle, @haystack;


=head1 CONFIGURATION AND ENVIRONMENT

This module should run under any Perl from 5.8.0 onward.  This is an XS module,
which means the build process requires a C compiler.  For most systems this
isn't an issue.  For some users (ActiveState Perl users, for example), it may be
advantageous to install a pre-built PPM distribution of this module.

While it's perfectly Ok to use this module directly, a more flexible approach
for the end user would be to C<use List::BinarySearch;>, while ensuring that
L<List::BinarySearch::XS> is installed on the target machine.
L<List::BinarySearch> will use the XS version automatically if it's installed,
and will downgrade gracefully to the pure-Perl version of
L<List::BinarySearch::XS> isn't installed.

Users of L<List::BinarySearch> may override this behavior by setting
C<$ENV{List_BinarySearch_PP}> to a true value.


=head1 DEPENDENCIES

This module requires Perl 5.8 or newer.

As mentioned above, the recommended point of entry is to install both this
module and L<List::BinarySearch>.  If both are installed, using
L<List::BinarySearch> will automatically use L<List::BinarySearch::XS> for
optimal performance.


=head1 INCOMPATIBILITIES

Currently L<List::BinarySearch::XS>, makes no attempt at compatibility with
the XS API for versions of Perl that predate Perl 5.8.  Perl 5.6 was replaced
by Perl 5.8 in July 2002.  It's time to move on.  Patches that establish
compatibility with earlier Perl versions will be considered (and welcomed) if
they have no measurable impact on efficiency, and especially if they come in
the form of a git patch, complete with tests. ;)


=head1 AUTHOR

David Oswald, C<< <davido at cpan.org> >>

If the documentation fails to answer your question, or if you have a comment
or suggestion, send me an email.


=head1 DIAGNOSTICS


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
L<https://github.com/daoswald/List-BinarySearch-XS/issues>.  I will be 
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

L<List::BinarySearch::XS> does not provide the C<binsearch_range> function that
appears in L<List::BinarySearch>.  However, L<List::BinarySearch> is used, and
this XS module is installed, that function will be available.  See the POD for
L<List::BinarySearch> for details.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::BinarySearch::XS

This module is maintained in a public repo at Github.  You may look for
information at:

=over 4

=item * Github: Development is hosted on Github at:

L<http://www.github.com/daoswald/List-BinarySearch-XS>

=item * GitHub Issue tracker (report bugs here)

L<https://github.com/daoswald/List-BinarySearch-XS/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/List-BinarySearch-XS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/List-BinarySearch-XS>

=item * Search CPAN

L<http://search.cpan.org/dist/List-BinarySearch-XS/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks toL<Mastering Algorithms with Perl|http://shop.oreilly.com/product/9781565923980.do>,
from L<O'Reilly|http://www.oreilly.com>: for the inspiration (and much of the
code) behind the positional search.  Quoting Mastering Algorithms with Perl:
"I<...the binary search was first documented in 1946 but the first algorithm
that worked for all sizes of array was not published until 1962.>" (A summary of
a passage from Knuth: Sorting and Searching, 6.2.1.)

I<Although the basic idea of binary search is comparatively straightforward,
the details can be surprisingly tricky...>  -- Donald Knuth


=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
