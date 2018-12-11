package List::AllUtils;

use strict;
use warnings;

our $VERSION = '0.15';

use List::Util 1.45      ();
use List::SomeUtils 0.56 ();
use List::UtilsBy 0.11   ();

BEGIN {
    my %imported;
    for my $module (qw( List::Util List::SomeUtils List::UtilsBy )) {
        my @ok = do {
            ## no critic (TestingAndDebugging::ProhibitNoStrict)
            no strict 'refs';
            @{ $module . '::EXPORT_OK' };
        };

        $module->import( grep { !$imported{$_} } @ok );

        @imported{@ok} = ($module) x @ok;
    }
}

use base 'Exporter';

our @EXPORT_OK = List::Util::uniqstr(
    @List::Util::EXPORT_OK,
    @List::SomeUtils::EXPORT_OK,
    @List::UtilsBy::EXPORT_OK,
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

1;

# ABSTRACT: Combines List::Util, List::SomeUtils and List::UtilsBy in one bite-sized package

__END__

=pod

=encoding UTF-8

=head1 NAME

List::AllUtils - Combines List::Util, List::SomeUtils and List::UtilsBy in one bite-sized package

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use List::AllUtils qw( first any );

    # _Everything_ from List::Util, List::SomeUtils, and List::UtilsBy
    use List::AllUtils qw( :all );

    my @numbers = ( 1, 2, 3, 5, 7 );
    # or don't import anything
    return List::AllUtils::first { $_ > 5 } @numbers;

=head1 DESCRIPTION

Are you sick of trying to remember whether a particular helper is
defined in L<List::Util>,  L<List::SomeUtils> or L<List::UtilsBy>? I sure am. Now you
don't have to remember. This module will export all of the functions
that either of those three modules defines.

Note that all function documentation has been shamelessly copied from
L<List::Util>, L<List::SomeUtils> and L<List::UtilsBy>.

=head2 Which One Wins?

Recently, L<List::Util> has started including some of the subs that used to
only be in L<List::SomeUtils>. Similar, L<List::SomeUtils> has some small
overlap with L<List::UtilsBy>. C<List::AllUtils> always favors the version
provided by L<List::Util>, L<List::SomeUtils> or L<List::UtilsBy> in that
order.

The docs below come from L<List::Util> 1.31, L<List::SomeUtils> 0.50, and
L<List::UtilsBy> 0.10.

=head1 WHAT IS EXPORTED?

All this module does is load L<List::Util>, L<List::SomeUtils>, and
L<List::UtilsBy>, and then re-export everything that they provide. That means
that regardless of the documentation below, you will get any subroutine that
your installed version provides.

=head1 LIST-REDUCTION FUNCTIONS

The following set of functions all reduce a list down to a single value.

=head2 reduce BLOCK LIST

Reduces LIST by calling BLOCK, in a scalar context, multiple times,
setting C<$a> and C<$b> each time. The first call will be with C<$a>
and C<$b> set to the first two elements of the list, subsequent
calls will be done by setting C<$a> to the result of the previous
call and C<$b> to the next element in the list.

Returns the result of the last call to BLOCK. If LIST is empty then
C<undef> is returned. If LIST only contains one element then that
element is returned and BLOCK is not executed.

    $foo = reduce { $a < $b ? $a : $b } 1..10       # min
    $foo = reduce { $a lt $b ? $a : $b } 'aa'..'zz' # minstr
    $foo = reduce { $a + $b } 1 .. 10               # sum
    $foo = reduce { $a . $b } @bar                  # concat

If your algorithm requires that C<reduce> produce an identity value, then
make sure that you always pass that identity value as the first argument to prevent
C<undef> being returned

  $foo = reduce { $a + $b } 0, @values;             # sum with 0 identity value

The remaining list-reduction functions are all specialisations of this
generic idea.

=head2 first BLOCK LIST

Similar to C<grep> in that it evaluates BLOCK setting C<$_> to each element
of LIST in turn. C<first> returns the first element where the result from
BLOCK is a true value. If BLOCK never returns true or LIST was empty then
C<undef> is returned.

    $foo = first { defined($_) } @list    # first defined value in @list
    $foo = first { $_ > $value } @list    # first value in @list which
                                          # is greater than $value

This function could be implemented using C<reduce> like this

    $foo = reduce { defined($a) ? $a : wanted($b) ? $b : undef } undef, @list

for example wanted() could be defined() which would return the first
defined value in @list

=head2 max LIST

Returns the entry in the list with the highest numerical value. If the
list is empty then C<undef> is returned.

    $foo = max 1..10                # 10
    $foo = max 3,9,12               # 12
    $foo = max @bar, @baz           # whatever

This function could be implemented using C<reduce> like this

    $foo = reduce { $a > $b ? $a : $b } 1..10

=head2 maxstr LIST

Similar to C<max>, but treats all the entries in the list as strings
and returns the highest string as defined by the C<gt> operator.
If the list is empty then C<undef> is returned.

    $foo = maxstr 'A'..'Z'          # 'Z'
    $foo = maxstr "hello","world"   # "world"
    $foo = maxstr @bar, @baz        # whatever

This function could be implemented using C<reduce> like this

    $foo = reduce { $a gt $b ? $a : $b } 'A'..'Z'

=head2 min LIST

Similar to C<max> but returns the entry in the list with the lowest
numerical value. If the list is empty then C<undef> is returned.

    $foo = min 1..10                # 1
    $foo = min 3,9,12               # 3
    $foo = min @bar, @baz           # whatever

This function could be implemented using C<reduce> like this

    $foo = reduce { $a < $b ? $a : $b } 1..10

=head2 minstr LIST

Similar to C<min>, but treats all the entries in the list as strings
and returns the lowest string as defined by the C<lt> operator.
If the list is empty then C<undef> is returned.

    $foo = minstr 'A'..'Z'          # 'A'
    $foo = minstr "hello","world"   # "hello"
    $foo = minstr @bar, @baz        # whatever

This function could be implemented using C<reduce> like this

    $foo = reduce { $a lt $b ? $a : $b } 'A'..'Z'

=head2 sum LIST

Returns the sum of all the elements in LIST. If LIST is empty then
C<undef> is returned.

    $foo = sum 1..10                # 55
    $foo = sum 3,9,12               # 24
    $foo = sum @bar, @baz           # whatever

This function could be implemented using C<reduce> like this

    $foo = reduce { $a + $b } 1..10

=head2 sum0 LIST

Similar to C<sum>, except this returns 0 when given an empty list, rather
than C<undef>.

=head1 KEY/VALUE PAIR LIST FUNCTIONS

The following set of functions, all inspired by L<List::Pairwise>, consume
an even-sized list of pairs. The pairs may be key/value associations from a
hash, or just a list of values. The functions will all preserve the original
ordering of the pairs, and will not be confused by multiple pairs having the
same "key" value - nor even do they require that the first of each pair be a
plain string.

=head2 pairgrep BLOCK KVLIST

Similar to perl's C<grep> keyword, but interprets the given list as an
even-sized list of pairs. It invokes the BLOCK multiple times, in scalar
context, with C<$a> and C<$b> set to successive pairs of values from the
KVLIST.

Returns an even-sized list of those pairs for which the BLOCK returned true
in list context, or the count of the B<number of pairs> in scalar context.
(Note, therefore, in scalar context that it returns a number half the size
of the count of items it would have returned in list context).

    @subset = pairgrep { $a =~ m/^[[:upper:]]+$/ } @kvlist

Similar to C<grep>, C<pairgrep> aliases C<$a> and C<$b> to elements of the
given list. Any modifications of it by the code block will be visible to
the caller.

=head2 pairfirst BLOCK KVLIST

Similar to the C<first> function, but interprets the given list as an
even-sized list of pairs. It invokes the BLOCK multiple times, in scalar
context, with C<$a> and C<$b> set to successive pairs of values from the
KVLIST.

Returns the first pair of values from the list for which the BLOCK returned
true in list context, or an empty list of no such pair was found. In scalar
context it returns a simple boolean value, rather than either the key or the
value found.

    ( $key, $value ) = pairfirst { $a =~ m/^[[:upper:]]+$/ } @kvlist

Similar to C<grep>, C<pairfirst> aliases C<$a> and C<$b> to elements of the
given list. Any modifications of it by the code block will be visible to
the caller.

=head2 pairmap BLOCK KVLIST

Similar to perl's C<map> keyword, but interprets the given list as an
even-sized list of pairs. It invokes the BLOCK multiple times, in list
context, with C<$a> and C<$b> set to successive pairs of values from the
KVLIST.

Returns the concatenation of all the values returned by the BLOCK in list
context, or the count of the number of items that would have been returned
in scalar context.

    @result = pairmap { "The key $a has value $b" } @kvlist

Similar to C<map>, C<pairmap> aliases C<$a> and C<$b> to elements of the
given list. Any modifications of it by the code block will be visible to
the caller.

=head2 pairs KVLIST

A convenient shortcut to operating on even-sized lists of pairs, this
function returns a list of ARRAY references, each containing two items from
the given list. It is a more efficient version of

    pairmap { [ $a, $b ] } KVLIST

It is most convenient to use in a C<foreach> loop, for example:

    foreach ( pairs @KVLIST ) {
       my ( $key, $value ) = @$_;
       ...
    }

=head2 pairkeys KVLIST

A convenient shortcut to operating on even-sized lists of pairs, this
function returns a list of the the first values of each of the pairs in
the given list. It is a more efficient version of

    pairmap { $a } KVLIST

=head2 pairvalues KVLIST

A convenient shortcut to operating on even-sized lists of pairs, this
function returns a list of the the second values of each of the pairs in
the given list. It is a more efficient version of

    pairmap { $b } KVLIST

=head1 OTHER FUNCTIONS

=head2 shuffle LIST

Returns the elements of LIST in a random order

    @cards = shuffle 0..51      # 0..51 in a random order

=head1 List::SomeUtils FUNCTIONS

=head2 Junctions

=head3 I<Treatment of an empty list>

There are two schools of thought for how to evaluate a junction on an
empty list:

=over

=item *

Reduction to an identity (boolean)

=item *

Result is undefined (three-valued)

=back

In the first case, the result of the junction applied to the empty list is
determined by a mathematical reduction to an identity depending on whether
the underlying comparison is "or" or "and".  Conceptually:

                    "any are true"      "all are true"
                    --------------      --------------
    2 elements:     A || B || 0         A && B && 1
    1 element:      A || 0              A && 1
    0 elements:     0                   1

In the second case, three-value logic is desired, in which a junction
applied to an empty list returns C<undef> rather than true or false

Junctions with a C<_u> suffix implement three-valued logic.  Those
without are boolean.

=head3 all BLOCK LIST

=head3 all_u BLOCK LIST

Returns a true value if all items in LIST meet the criterion given through
BLOCK. Sets C<$_> for each item in LIST in turn:

  print "All values are non-negative"
    if all { $_ >= 0 } ($x, $y, $z);

For an empty LIST, C<all> returns true (i.e. no values failed the condition)
and C<all_u> returns C<undef>.

Thus, C<< all_u(@list) >> is equivalent to C<< @list ? all(@list) : undef >>.

B<Note>: because Perl treats C<undef> as false, you must check the return value
of C<all_u> with C<defined> or you will get the opposite result of what you
expect.

=head3 any BLOCK LIST

=head3 any_u BLOCK LIST

Returns a true value if any item in LIST meets the criterion given through
BLOCK. Sets C<$_> for each item in LIST in turn:

  print "At least one non-negative value"
    if any { $_ >= 0 } ($x, $y, $z);

For an empty LIST, C<any> returns false and C<any_u> returns C<undef>.

Thus, C<< any_u(@list) >> is equivalent to C<< @list ? any(@list) : undef >>.

=head3 none BLOCK LIST

=head3 none_u BLOCK LIST

Logically the negation of C<any>. Returns a true value if no item in LIST meets
the criterion given through BLOCK. Sets C<$_> for each item in LIST in turn:

  print "No non-negative values"
    if none { $_ >= 0 } ($x, $y, $z);

For an empty LIST, C<none> returns true (i.e. no values failed the condition)
and C<none_u> returns C<undef>.

Thus, C<< none_u(@list) >> is equivalent to C<< @list ? none(@list) : undef >>.

B<Note>: because Perl treats C<undef> as false, you must check the return value
of C<none_u> with C<defined> or you will get the opposite result of what you
expect.

=head3 notall BLOCK LIST

=head3 notall_u BLOCK LIST

Logically the negation of C<all>. Returns a true value if not all items in LIST
meet the criterion given through BLOCK. Sets C<$_> for each item in LIST in
turn:

  print "Not all values are non-negative"
    if notall { $_ >= 0 } ($x, $y, $z);

For an empty LIST, C<notall> returns false and C<notall_u> returns C<undef>.

Thus, C<< notall_u(@list) >> is equivalent to C<< @list ? notall(@list) : undef >>.

=head3 one BLOCK LIST

=head3 one_u BLOCK LIST

Returns a true value if precisely one item in LIST meets the criterion
given through BLOCK. Sets C<$_> for each item in LIST in turn:

    print "Precisely one value defined"
        if one { defined($_) } @list;

Returns false otherwise.

For an empty LIST, C<one> returns false and C<one_u> returns C<undef>.

The expression C<one BLOCK LIST> is almost equivalent to
C<1 == true BLOCK LIST>, except for short-cutting.
Evaluation of BLOCK will immediately stop at the second true value.

=head2 Transformation

=head3 apply BLOCK LIST

Applies BLOCK to each item in LIST and returns a list of the values after BLOCK
has been applied. In scalar context, the last element is returned.  This
function is similar to C<map> but will not modify the elements of the input
list:

  my @list = (1 .. 4);
  my @mult = apply { $_ *= 2 } @list;
  print "\@list = @list\n";
  print "\@mult = @mult\n";
  __END__
  @list = 1 2 3 4
  @mult = 2 4 6 8

Think of it as syntactic sugar for

  for (my @mult = @list) { $_ *= 2 }

=head3 insert_after BLOCK VALUE LIST

Inserts VALUE after the first item in LIST for which the criterion in BLOCK is
true. Sets C<$_> for each item in LIST in turn.

  my @list = qw/This is a list/;
  insert_after { $_ eq "a" } "longer" => @list;
  print "@list";
  __END__
  This is a longer list

=head3 insert_after_string STRING VALUE LIST

Inserts VALUE after the first item in LIST which is equal to STRING.

  my @list = qw/This is a list/;
  insert_after_string "a", "longer" => @list;
  print "@list";
  __END__
  This is a longer list

=head3 pairwise BLOCK ARRAY1 ARRAY2

Evaluates BLOCK for each pair of elements in ARRAY1 and ARRAY2 and returns a
new list consisting of BLOCK's return values. The two elements are set to C<$a>
and C<$b>.  Note that those two are aliases to the original value so changing
them will modify the input arrays.

  @a = (1 .. 5);
  @b = (11 .. 15);
  @x = pairwise { $a + $b } @a, @b;     # returns 12, 14, 16, 18, 20

  # mesh with pairwise
  @a = qw/a b c/;
  @b = qw/1 2 3/;
  @x = pairwise { ($a, $b) } @a, @b;    # returns a, 1, b, 2, c, 3

=head3 mesh ARRAY1 ARRAY2 [ ARRAY3 ... ]

=head3 zip ARRAY1 ARRAY2 [ ARRAY3 ... ]

Returns a list consisting of the first elements of each array, then
the second, then the third, etc, until all arrays are exhausted.

Examples:

  @x = qw/a b c d/;
  @y = qw/1 2 3 4/;
  @z = mesh @x, @y;         # returns a, 1, b, 2, c, 3, d, 4

  @a = ('x');
  @b = ('1', '2');
  @c = qw/zip zap zot/;
  @d = mesh @a, @b, @c;   # x, 1, zip, undef, 2, zap, undef, undef, zot

C<zip> is an alias for C<mesh>.

=head3 uniq LIST

=head3 distinct LIST

Returns a new list by stripping duplicate values in LIST by comparing
the values as hash keys, except that undef is considered separate from ''.
The order of elements in the returned list is the same as in LIST. In
scalar context, returns the number of unique elements in LIST.

  my @x = uniq 1, 1, 2, 2, 3, 5, 3, 4; # returns 1 2 3 5 4
  my $x = uniq 1, 1, 2, 2, 3, 5, 3, 4; # returns 5
  # returns "Mike", "Michael", "Richard", "Rick"
  my @n = distinct "Mike", "Michael", "Richard", "Rick", "Michael", "Rick"
  # returns '', undef, 'S1', A5'
  my @s = distinct '', undef, 'S1', 'A5'
  # returns '', undef, 'S1', A5'
  my @w = uniq undef, '', 'S1', 'A5'

C<distinct> is an alias for C<uniq>.

B<RT#49800> can be used to give feedback about this behavior.

=head3 singleton

Returns a new list by stripping values in LIST occurring more than once by
comparing the values as hash keys, except that undef is considered separate
from ''.  The order of elements in the returned list is the same as in LIST.
In scalar context, returns the number of elements occurring only once in LIST.

  my @x = singleton 1,1,2,2,3,4,5 # returns 3 4 5

=head2 Partitioning

=head3 after BLOCK LIST

Returns a list of the values of LIST after (and not including) the point
where BLOCK returns a true value. Sets C<$_> for each element in LIST in turn.

  @x = after { $_ % 5 == 0 } (1..9);    # returns 6, 7, 8, 9

=head3 after_incl BLOCK LIST

Same as C<after> but also includes the element for which BLOCK is true.

=head3 before BLOCK LIST

Returns a list of values of LIST up to (and not including) the point where BLOCK
returns a true value. Sets C<$_> for each element in LIST in turn.

=head3 before_incl BLOCK LIST

Same as C<before> but also includes the element for which BLOCK is true.

=head3 part BLOCK LIST

Partitions LIST based on the return value of BLOCK which denotes into which
partition the current value is put.

Returns a list of the partitions thusly created. Each partition created is a
reference to an array.

  my $i = 0;
  my @part = part { $i++ % 2 } 1 .. 8;   # returns [1, 3, 5, 7], [2, 4, 6, 8]

You can have a sparse list of partitions as well where non-set partitions will
be undef:

  my @part = part { 2 } 1 .. 10;            # returns undef, undef, [ 1 .. 10 ]

Be careful with negative values, though:

  my @part = part { -1 } 1 .. 10;
  __END__
  Modification of non-creatable array value attempted, subscript -1 ...

Negative values are only ok when they refer to a partition previously created:

  my @idx  = ( 0, 1, -1 );
  my $i    = 0;
  my @part = part { $idx[$++ % 3] } 1 .. 8; # [1, 4, 7], [2, 3, 5, 6, 8]

=head2 Iteration

=head3 each_array ARRAY1 ARRAY2 ...

Creates an array iterator to return the elements of the list of arrays ARRAY1,
ARRAY2 throughout ARRAYn in turn.  That is, the first time it is called, it
returns the first element of each array.  The next time, it returns the second
elements.  And so on, until all elements are exhausted.

This is useful for looping over more than one array at once:

  my $ea = each_array(@a, @b, @c);
  while ( my ($a, $b, $c) = $ea->() )   { .... }

The iterator returns the empty list when it reached the end of all arrays.

If the iterator is passed an argument of 'C<index>', then it returns
the index of the last fetched set of values, as a scalar.

=head3 each_arrayref LIST

Like each_array, but the arguments are references to arrays, not the
plain arrays.

=head3 natatime EXPR, LIST

Creates an array iterator, for looping over an array in chunks of
C<$n> items at a time.  (n at a time, get it?).  An example is
probably a better explanation than I could give in words.

Example:

  my @x = ('a' .. 'g');
  my $it = natatime 3, @x;
  while (my @vals = $it->())
  {
    print "@vals\n";
  }

This prints

  a b c
  d e f
  g

=head2 Searching

=head3 bsearch BLOCK LIST

Performs a binary search on LIST which must be a sorted list of values. BLOCK
must return a negative value if the current element (stored in C<$_>) is smaller,
a positive value if it is bigger and zero if it matches.

Returns a boolean value in scalar context. In list context, it returns the element
if it was found, otherwise the empty list.

=head3 bsearchidx BLOCK LIST

=head3 bsearch_index BLOCK LIST

Performs a binary search on LIST which must be a sorted list of values. BLOCK
must return a negative value if the current element (stored in C<$_>) is smaller,
a positive value if it is bigger and zero if it matches.

Returns the index of found element, otherwise C<-1>.

C<bsearch_index> is an alias for C<bsearchidx>.

=head3 firstval BLOCK LIST

=head3 first_value BLOCK LIST

Returns the first element in LIST for which BLOCK evaluates to true. Each
element of LIST is set to C<$_> in turn. Returns C<undef> if no such element
has been found.

C<first_value> is an alias for C<firstval>.

=head3 onlyval BLOCK LIST

=head3 only_value BLOCK LIST

Returns the only element in LIST for which BLOCK evaluates to true. Sets
C<$_> for each item in LIST in turn. Returns C<undef> if no such element
has been found.

C<only_value> is an alias for C<onlyval>.

=head3 lastval BLOCK LIST

=head3 last_value BLOCK LIST

Returns the last value in LIST for which BLOCK evaluates to true. Each element
of LIST is set to C<$_> in turn. Returns C<undef> if no such element has been
found.

C<last_value> is an alias for C<lastval>.

=head3 firstres BLOCK LIST

=head3 first_result BLOCK LIST

Returns the result of BLOCK for the first element in LIST for which BLOCK
evaluates to true. Each element of LIST is set to C<$_> in turn. Returns
C<undef> if no such element has been found.

C<first_result> is an alias for C<firstres>.

=head3 onlyres BLOCK LIST

=head3 only_result BLOCK LIST

Returns the result of BLOCK for the first element in LIST for which BLOCK
evaluates to true. Sets C<$_> for each item in LIST in turn. Returns
C<undef> if no such element has been found.

C<only_result> is an alias for C<onlyres>.

=head3 lastres BLOCK LIST

=head3 last_result BLOCK LIST

Returns the result of BLOCK for the last element in LIST for which BLOCK
evaluates to true. Each element of LIST is set to C<$_> in turn. Returns
C<undef> if no such element has been found.

C<last_result> is an alias for C<lastres>.

=head3 indexes BLOCK LIST

Evaluates BLOCK for each element in LIST (assigned to C<$_>) and returns a list
of the indices of those elements for which BLOCK returned a true value. This is
just like C<grep> only that it returns indices instead of values:

  @x = indexes { $_ % 2 == 0 } (1..10);   # returns 1, 3, 5, 7, 9

=head3 firstidx BLOCK LIST

=head3 first_index BLOCK LIST

Returns the index of the first element in LIST for which the criterion in BLOCK
is true. Sets C<$_> for each item in LIST in turn:

  my @list = (1, 4, 3, 2, 4, 6);
  printf "item with index %i in list is 4", firstidx { $_ == 4 } @list;
  __END__
  item with index 1 in list is 4

Returns C<-1> if no such item could be found.

C<first_index> is an alias for C<firstidx>.

=head3 onlyidx BLOCK LIST

=head3 only_index BLOCK LIST

Returns the index of the only element in LIST for which the criterion
in BLOCK is true. Sets C<$_> for each item in LIST in turn:

    my @list = (1, 3, 4, 3, 2, 4);
    printf "uniqe index of item 2 in list is %i", onlyidx { $_ == 2 } @list;
    __END__
    unique index of item 2 in list is 4

Returns C<-1> if either no such item or more than one of these
has been found.

C<only_index> is an alias for C<onlyidx>.

=head3 lastidx BLOCK LIST

=head3 last_index BLOCK LIST

Returns the index of the last element in LIST for which the criterion in BLOCK
is true. Sets C<$_> for each item in LIST in turn:

  my @list = (1, 4, 3, 2, 4, 6);
  printf "item with index %i in list is 4", lastidx { $_ == 4 } @list;
  __END__
  item with index 4 in list is 4

Returns C<-1> if no such item could be found.

C<last_index> is an alias for C<lastidx>.

=head2 Sorting

=head3 sort_by BLOCK LIST

Returns the list of values sorted according to the string values returned by the
KEYFUNC block or function. A typical use of this may be to sort objects according
to the string value of some accessor, such as

  sort_by { $_->name } @people

The key function is called in scalar context, being passed each value in turn as
both $_ and the only argument in the parameters, @_. The values are then sorted
according to string comparisons on the values returned.
This is equivalent to

  sort { $a->name cmp $b->name } @people

except that it guarantees the name accessor will be executed only once per value.
One interesting use-case is to sort strings which may have numbers embedded in them
"naturally", rather than lexically.

  sort_by { s/(\d+)/sprintf "%09d", $1/eg; $_ } @strings

This sorts strings by generating sort keys which zero-pad the embedded numbers to
some level (9 digits in this case), helping to ensure the lexical sort puts them
in the correct order.

=head3 nsort_by BLOCK LIST

Similar to sort_by but compares its key values numerically.

=head2 Counting and calculation

=head3 true BLOCK LIST

Counts the number of elements in LIST for which the criterion in BLOCK is true.
Sets C<$_> for  each item in LIST in turn:

  printf "%i item(s) are defined", true { defined($_) } @list;

=head3 false BLOCK LIST

Counts the number of elements in LIST for which the criterion in BLOCK is false.
Sets C<$_> for each item in LIST in turn:

  printf "%i item(s) are not defined", false { defined($_) } @list;

=head3 minmax LIST

Calculates the minimum and maximum of LIST and returns a two element list with
the first element being the minimum and the second the maximum. Returns the
empty list if LIST was empty.

The C<minmax> algorithm differs from a naive iteration over the list where each
element is compared to two values being the so far calculated min and max value
in that it only requires 3n/2 - 2 comparisons. Thus it is the most efficient
possible algorithm.

However, the Perl implementation of it has some overhead simply due to the fact
that there are more lines of Perl code involved. Therefore, LIST needs to be
fairly big in order for C<minmax> to win over a naive implementation. This
limitation does not apply to the XS version.

=head3 mode LIST

Calculates the most common items in the list and returns them as a list. This
is effectively done by string comparisons, so references will be
stringified. If they implement string overloading, this will be used.

If more than one item appears the same number of times in the list, all such
items will be returned. For example, the mode of a unique list is the list
itself.

This function B<always> returns a list. That means that in scalar context you
get a count indicating the number of modes in the list.

=head1 List::UtilsBy Functions

=head2 rev_sort_by

=head2 rev_nsort_by

   @vals = rev_sort_by { KEYFUNC } @vals

   @vals = rev_nsort_by { KEYFUNC } @vals

I<Since version 0.06.>

Similar to L</sort_by> and L</nsort_by> but returns the list in the reverse
order. Equivalent to

   @vals = reverse sort_by { KEYFUNC } @vals

except that these functions are slightly more efficient because they avoid
the final C<reverse> operation.

=head2 max_by

   $optimal = max_by { KEYFUNC } @vals

   @optimal = max_by { KEYFUNC } @vals

Returns the (first) value from C<@vals> that gives the numerically largest
result from the key function.

   my $tallest = max_by { $_->height } @people

   use File::stat qw( stat );
   my $newest = max_by { stat($_)->mtime } @files;

In scalar context, the first maximal value is returned. In list context, a
list of all the maximal values is returned. This may be used to obtain
positions other than the first, if order is significant.

If called on an empty list, an empty list is returned.

For symmetry with the L</nsort_by> function, this is also provided under the
name C<nmax_by> since it behaves numerically.

=head2 min_by

   $optimal = min_by { KEYFUNC } @vals

   @optimal = min_by { KEYFUNC } @vals

Similar to L</max_by> but returns values which give the numerically smallest
result from the key function. Also provided as C<nmin_by>

=head2 minmax_by

   ( $minimal, $maximal ) = minmax_by { KEYFUNC } @vals

Similar to calling both L</min_by> and L</max_by> with the same key function
on the same list. This version is more efficient than calling the two other
functions individually, as it has less work to perform overall. In the case of
ties, only the first optimal element found in each case is returned. Also
provided as C<nminmax_by>.

=head2 uniq_by

   @vals = uniq_by { KEYFUNC } @vals

Returns a list of the subset of values for which the key function block
returns unique values. The first value yielding a particular key is chosen,
subsequent values are rejected.

   my @some_fruit = uniq_by { $_->colour } @fruit;

To select instead the last value per key, reverse the input list. If the order
of the results is significant, don't forget to reverse the result as well:

   my @some_fruit = reverse uniq_by { $_->colour } reverse @fruit;

Because the values returned by the key function are used as hash keys, they
ought to either be strings, or at least well-behaved as strings (such as
numbers, or object references which overload stringification in a suitable
manner).

=head2 partition_by

   %parts = partition_by { KEYFUNC } @vals

Returns a key/value list of ARRAY refs containing all the original values
distributed according to the result of the key function block. Each value will
be an ARRAY ref containing all the values which returned the string from the
key function, in their original order.

   my %balls_by_colour = partition_by { $_->colour } @balls;

Because the values returned by the key function are used as hash keys, they
ought to either be strings, or at least well-behaved as strings (such as
numbers, or object references which overload stringification in a suitable
manner).

=head2 count_by

   %counts = count_by { KEYFUNC } @vals

Returns a key/value list of integers, giving the number of times the key
function block returned the key, for each value in the list.

   my %count_of_balls = count_by { $_->colour } @balls;

Because the values returned by the key function are used as hash keys, they
ought to either be strings, or at least well-behaved as strings (such as
numbers, or object references which overload stringification in a suitable
manner).

=head2 zip_by

   @vals = zip_by { ITEMFUNC } \@arr0, \@arr1, \@arr2,...

Returns a list of each of the values returned by the function block, when
invoked with values from across each each of the given ARRAY references. Each
value in the returned list will be the result of the function having been
invoked with arguments at that position, from across each of the arrays given.

   my @transposition = zip_by { [ @_ ] } @matrix;

   my @names = zip_by { "$_[1], $_[0]" } \@firstnames, \@surnames;

   print zip_by { "$_[0] => $_[1]\n" } [ keys %hash ], [ values %hash ];

If some of the arrays are shorter than others, the function will behave as if
they had C<undef> in the trailing positions. The following two lines are
equivalent:

   zip_by { f(@_) } [ 1, 2, 3 ], [ "a", "b" ]
   f( 1, "a" ), f( 2, "b" ), f( 3, undef )

The item function is called by C<map>, so if it returns a list, the entire
list is included in the result. This can be useful for example, for generating
a hash from two separate lists of keys and values

   my %nums = zip_by { @_ } [qw( one two three )], [ 1, 2, 3 ];
   # %nums = ( one => 1, two => 2, three => 3 )

(A function having this behaviour is sometimes called C<zipWith>, e.g. in
Haskell, but that name would not fit the naming scheme used by this module).

=head2 unzip_by

   $arr0, $arr1, $arr2, ... = unzip_by { ITEMFUNC } @vals

Returns a list of ARRAY references containing the values returned by the
function block, when invoked for each of the values given in the input list.
Each of the returned ARRAY references will contain the values returned at that
corresponding position by the function block. That is, the first returned
ARRAY reference will contain all the values returned in the first position by
the function block, the second will contain all the values from the second
position, and so on.

   my ( $firstnames, $lastnames ) = unzip_by { m/^(.*?) (.*)$/ } @names;

If the function returns lists of differing lengths, the result will be padded
with C<undef> in the missing elements.

This function is an inverse of L</zip_by>, if given a corresponding inverse
function.

=head2 extract_by

   @vals = extract_by { SELECTFUNC } @arr

Removes elements from the referenced array on which the selection function
returns true, and returns a list containing those elements. This function is
similar to C<grep>, except that it modifies the referenced array to remove the
selected values from it, leaving only the unselected ones.

   my @red_balls = extract_by { $_->color eq "red" } @balls;

   # Now there are no red balls in the @balls array

This function modifies a real array, unlike most of the other functions in this
module. Because of this, it requires a real array, not just a list.

This function is implemented by invoking C<splice> on the array, not by
constructing a new list and assigning it. One result of this is that weak
references will not be disturbed.

   extract_by { !defined $_ } @refs;

will leave weak references weakened in the C<@refs> array, whereas

   @refs = grep { defined $_ } @refs;

will strengthen them all again.

=head2 extract_first_by

   $val = extract_first_by { SELECTFUNC } @arr

A hybrid between L</extract_by> and C<List::Util::first>. Removes the first
element from the referenced array on which the selection function returns
true, returning it.

As with L</extract_by>, this function requires a real array and not just a
list, and is also implemented using C<splice> so that weak references are
not disturbed.

If this function fails to find a matching element, it will return an empty
list in list context. This allows a caller to distinguish the case between
no matching element, and the first matching element being C<undef>.

=head2 weighted_shuffle_by

   @vals = weighted_shuffle_by { WEIGHTFUNC } @vals

Returns the list of values shuffled into a random order. The randomisation is
not uniform, but weighted by the value returned by the C<WEIGHTFUNC>. The
probability of each item being returned first will be distributed with the
distribution of the weights, and so on recursively for the remaining items.

=head2 bundle_by

   @vals = bundle_by { BLOCKFUNC } $number, @vals

Similar to a regular C<map> functional, returns a list of the values returned
by C<BLOCKFUNC>. Values from the input list are given to the block function in
bundles of C<$number>.

If given a list of values whose length does not evenly divide by C<$number>,
the final call will be passed fewer elements than the others.

=head1 EXPORTS

This module exports nothing by default. You can import functions by
name, or get everything with the C<:all> tag.

=head1 SEE ALSO

L<List::Util>,  L<List::SomeUtils> and L<List::UtilsBy>, obviously.

Also see C<Util::Any>, which unifies many more util modules, and also
lets you rename functions as part of the import.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-list-allutils@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=List-AllUtils> or via email to L<bug-list-allutils@rt.cpan.org|mailto:bug-list-allutils@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for List-AllUtils can be found at L<https://github.com/houseabsolute/List-AllUtils>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Ricardo Signes Yanick Champoux

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
