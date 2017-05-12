## no critic (RCS,prototypes)

package List::BinarySearch;

use 5.008000;
use strict;
use warnings;
use Carp;

use Scalar::Util qw( looks_like_number );


BEGIN {

  my @imports = qw( binsearch binsearch_pos );

  # Import XS by default, pure-Perl if XS is unavailable, or if
  # $ENV{List_BinarySearch_PP} is set.

  # This conditional has been tested manually.  Can't be automatically tested.
  # uncoverable condition right false
  if (
       $ENV{List_BinarySearch_PP}
    || ! eval 'use List::BinarySearch::XS @imports; 1;'  ## no critic (eval)
  ) {
    eval 'use List::BinarySearch::PP  @imports;';        ## no critic (eval)
  }

}

require Exporter;

our @ISA       = qw(Exporter);    ## no critic (ISA)

# Note: binsearch and binsearch_pos come from List::BinarySearch::PP
our @EXPORT_OK = qw(  binsearch         binsearch_pos       binsearch_range  );

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# The prototyping gives List::BinarySearch a similar feel to List::Util,
# and List::MoreUtils.

our $VERSION = '0.25';

# Needed for developer's releases: See perlmodstyle.
# $VERSION = eval $VERSION;    ## no critic (eval,version)


# Custom import() to touch $a and $b in Perl version < 5.20, to eliminate
# "used only once" warnings.
{
  if( $] < 5.020 ) {
    *import = sub {
      my $pkg = caller;
      no strict 'refs'; ## no critic(strict)
      ${"${pkg}::a"} = ${"${pkg}::a"};
      ${"${pkg}::b"} = ${"${pkg}::b"};
      # It would feel nicer to call shift->SUPER::import(@_), but 
      # Exporter::import appears to be too fragile for this type of wrapper.
      goto &Exporter::import;
    };
  }
}



# binsearch and binsearch_pos will be loaded from List::BinarySearch::PP or
# List::BinarySearch::XS.



sub binsearch_range (&$$\@) {
  my( $code, $low_target, $high_target, $aref ) = @_;
  my( $index_low, $index_high );

  # Forward along the caller's $a and $b.
  local( *a, *b ) = do{
    no strict 'refs';  ## no critic (strict)
    my $pkg = caller();
    ( *{$pkg.'::a'}, *{$pkg.'::b'} );
  };
  $index_low  = binsearch_pos( \&$code, $low_target,  @$aref );
  $index_high = binsearch_pos( \&$code, $high_target, @$aref );
  local( $a, $b ) = ( $aref->[$index_high], $high_target ); # Use our own.
  if(  $index_high == scalar @$aref    or    $code->( $a, $b ) > 0  )
  {
    $index_high--;
  }
  return ( $index_low, $index_high );
}



1;    # End of List::BinarySearch

__END__

=head1 NAME

List::BinarySearch - Binary Search within a sorted array.

=head1 SYNOPSIS

This module performs a binary search on an array.

Examples:


    use List::BinarySearch qw( :all );  # ... or ...
    use List::BinarySearch qw( binsearch  binsearch_pos  binsearch_range );


    # Some ordered arrays to search within.
    @num_array =   ( 100, 200, 300, 400, 500 );
    @str_array = qw( Bach Beethoven Brahms Mozart Schubert );


    # Find the lowest index of a matching element.

    $index = binsearch {$a <=> $b} 300, @num_array;
    $index = binsearch {$a cmp $b} 'Mozart', @str_array;      # Stringy cmp.
    $index = binsearch {$a <=> $b} 42, @num_array;            # not found: undef


    # Find the lowest index of a matching element, or best insert point.

    $index = binsearch_pos {$a cmp $b} 'Chopin', @str_array;  # Insert at [3].
    $index = binsearch_pos {$a <=> $b} 600, @num_array;       # Insert at [5].

    splice @num_array, $index, 0, 600
      if( $num_array[$index] != 600 );                        # Insertion at [5]

    $index = binsearch_pos { $a <=> $b } 200, @num_array;     # Matched at [1].


    # The following functions return an inclusive range.

    my( $low_ix, $high_ix )
        = binsearch_range { $a cmp $b } 'Beethoven', 'Mozart', @str_array;
        # Returns ( 1, 3 ), meaning ( 1 .. 3 ).

    my( $low_ix, $high_ix )
        = binsearch_range { $a <=> $b } 200, 400, @num_array;



=head1 DESCRIPTION

A binary search searches B<sorted> lists using a divide and conquer technique.
On each iteration the search domain is cut in half, until the result is found.
The computational complexity of a binary search is O(log n).

The binary search algorithm implemented in this module is known as a
I<Deferred Detection> variant on the traditional Binary Search.  Deferred
Detection provides B<stable searches>.  Stable binary search algorithms have
the following characteristics, contrasted with their unstable binary search
cousins:

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

B<< This module has a companion "XS" module: L<List::BinarySearch::XS> which
users are strongly encouraged to install as well. >>  If List::BinarySearch::XS
is also installed, C<binsearch> and C<binsearch_pos> will use XS code.  This
behavior may be overridden by setting C<$ENV{List_BinarySearch_PP}> to a
true value.  Most CPAN installers will either automatically install the XS
module, or prompt to automatically install it.  See CONFIGURATION for details.


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

So to answer the question, you might use a module so that you
don't have to write, test, and debug your own implementation.


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

Nothing is exported by default.  C<binsearch>, C<binsearch_pos>, and
C<binsearch_range> may be exported by listing them on the export list.

Or import all functions by specifying C<:all>.

=head1 SUBROUTINES/METHODS

=head2 WHICH SEARCH ROUTINE TO USE

=over 4

=item * C<binsearch>: Returns lowest index where match is found, or undef.

=item * C<binsearch_pos>: Returns lowest index where match is found, or the
index of the best insert point for needle if the needle isn't found.

=item * C<binsearch_range>: Performs a search for both low and high needles.
Returns a pair of indices refering to a range of elements corresponding to
low and high needles.

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


=head2 binsearch_range CODE LOW_NEEDLE HIGH_NEEDLE ARRAY_HAYSTACK

    my( $low, $high )
      = binsearch_range { $a <=> $b }, $low_needle, $high_needle, @haystack;

Given C<$low_needle> and C<$high_needle>, returns a set of indices that
represent the range of elements fitting within C<$low_needle> and
C<$high_needle>'s bounds.  This might be useful, for example, in finding all
transations that occurred between 02012013 and 02292013.

I<This algorithm was adapted from Mastering Algorithms with Perl, page 172 and
173.>

=head2 The callback block (The comparator)

Comparators in L<List::BinarySearch> are used to compare the target (needle)
with individual haystack elements, returning the result of the relational
comparison of the two values.  A good example would be the code block in a
C<sort> function.

Basic comparators might be defined like this:

    # Numeric comparisons:
    binsearch { $a <=> $b } $needle, @haystack;

    # Stringwise comparisons:
    binsearch { $a cmp $b } $needle, @haystack;

    # Unicode Collation Algorithm comparisons
    $Collator = Unicode::Collate->new;
    binsearch { $Collator->( $a, $b ) } $needle, @haystack;

C<$a> represents the target.  C<$b> represents the contents of the haystack
element being tested.  This leads to an asymmetry that might be prone to
"gotchas" when writing custom comparators for searching complex data structures.
As an example, consider the following data structure:

    my @structure = (
        [ 100, 'ape'  ],
        [ 200, 'cat'  ],
        [ 300, 'dog'  ],
        [ 400, 'frog' ]
    );

A numeric custom comparator for such a data structure would look like this:

    sub{ $a <=> $b->[0] }

In this regard, the callback is unlike C<sort>, because C<sort> is always
comparing to elements, whereas C<binsearch> is comparing a target with an
element.

Just as with C<sort>, the comparator must return -1, 0, or 1 to signify "less
than", "equal to", or "greater than".


=head1 DATA SET REQUIREMENTS

A well written general algorithm should place as few demands on its data as
practical.  The requirements that these Binary Search algorithms impose are:

=over 4

=item * B<The list must be in ascending sorted order>.

This is a big one.  The best sort routines run in O(n log n) time.  It makes no
sense to sort a list in O(n log n) time, and then perform a single O(log n)
binary search when List::Util C<first> could accomplish the same thing in O(n)
time without sorting.

=item * B<The list must be in ascending sorted order.>

A Binary Search consumes O(log n) time. We don't want to waste linear time
verifying the list is sordted, so B<there is no validity checking. You have
been warned.>

=item * B<These functions are prototyped> as (&$\@) or ($\@).

What this implementation detail means is that C<@haystack> is implicitly passed
by reference.  This is the price we pay for a familiar user interface, cleaner
calling syntax, and the automatic efficiency of pass-by-reference.

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

    my $found_index = binsearch { $Collator->cmp($a, $b) } $needle, @haystack;


=head1 CONFIGURATION AND ENVIRONMENT

List::BinarySearch is a thin layer that will attempt to load
List::BinarySearch::XS first, and if that module is unavailable, will fall back
to List::BinarySearch::PP which is provided with this distribution.

Most CPAN installers will automatically pull in and install the XS plugin 
for this module.  If in interactive mode, they will prompt first. To override 
default behavior, forcing CPAN installers to I<not> pull in the XS module, 
set the environment variable LBS_NO_XS true prior to installation.  There
will be no prompt, and the XS module won't be pulled in and installed.
However, the List::BinarySearch::XS plugin is strongly recommended, and should
only be skipped in environments where XS modules cannot be compiled.

If one wishes to install the XS module beforhand, or at any time later on, just
installing it in the usual fashion is sufficient for List::BinarySearch to
recognize and start using it.

By installing L<List::BinarySearch::XS>, the pure-Perl versions of C<binsearch>
and C<binsearch_pos> will be automatically replaced with XS versions for
markedly improved performance.  C<binsearch_range> also benefits from the XS
plug-in, since internally it makes calls to C<binsearch_pos>.

Users are strongly advised to install L<List::BinarySearch::XS>.  If, after
installing List::BinarySearch::XS, one wishes to disable the XS plugin, setting
C<$ENV{List_BinarySearch_PP}> to a true value will prevent the XS module from
being used by L<List::BinarySearch>.  This setting will have no effect on users
who use List::BinarySearch::XS directly.

For the sake of code portability, it is recommended to use List::BinarySearch 
as the front-end, as it will automatically and portably downgrade to the 
pure-Perl version if the XS module can't be loaded.


=head1 DEPENDENCIES

This module uses L<Exporter|Exporter>, and automatically makes use of
L<List::BinarySearch::XS> if it's installed on the user's system.

This module will attempt to install List::BinarySearch::XS unless the
environment variable C<LBS_NO_XS> is set prior to install, or if in interactive
mode, the user opts to skip this recommended step.

This module supports Perl versions 5.8 and newer.
The optional XS extension also supports Perl 5.8 and newer.


=head1 INCOMPATIBILITIES

This module is incompatible with Perl versions prior to 5.8.  In particular,
its use of prototypes isn't compatible with Perl 5.6 or older.  It would be
easy to eliminate the use of prototypes, but doing so would change calling
syntax.


=head1 DIAGNOSTICS


=head1 SEE ALSO

L<List::BinarySearch::XS>: An XS plugin for this module; install it, and this
module will use it automatically for a nice performance improvement.  May also
be used on its own.

=head1 AUTHOR

David Oswald, C<< <davido at cpan.org> >>

If the documentation fails to answer a question, or if you have a comment or 
suggestion, send me an email.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
L<https://github.com/daoswald/List-BinarySearch/issues>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.



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

Thank-you to those who provided advice on user interface and XS
interoperability.

L<Mastering Algorithms with Perl|http://shop.oreilly.com/product/9781565923980.do>,
from L<O'Reilly|http://www.oreilly.com>: for the inspiration (and much of the
code) behind the positional and ranged searches.  Quoting MAwP: "I<...the
binary search was first documented in 1946 but the first algorithm that worked
for all sizes of array was not published until 1962.>" (A summary of a passage
from Knuth: Sorting and Searching, 6.2.1.)

I<Although the basic idea of binary search is comparatively straightforward,
the details can be surprisingly tricky...>  -- Donald Knuth


=head1 LICENSE AND COPYRIGHT

Copyright 2012 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
