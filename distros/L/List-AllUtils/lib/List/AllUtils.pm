package List::AllUtils;

use strict;
use warnings;

our $VERSION = '0.19';

use List::Util 1.56      ();
use List::SomeUtils 0.58 ();
use List::UtilsBy 0.11   ();

BEGIN {
    my %skip = (
        'List::Util' => {
            mesh => 1,
            zip  => 1,
        },
    );

    my %imported;
    for my $module (qw( List::Util List::SomeUtils List::UtilsBy )) {
        my @ok = do {
            ## no critic (TestingAndDebugging::ProhibitNoStrict)
            no strict 'refs';
            grep { !$skip{$module}{$_} } @{ $module . '::EXPORT_OK' };
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

version 0.19

=head1 SYNOPSIS

    use List::AllUtils qw( first any );

    # _Everything_ from List::Util, List::SomeUtils, and List::UtilsBy
    use List::AllUtils qw( :all );

    my @numbers = ( 1, 2, 3, 5, 7 );
    # or don't import anything
    return List::AllUtils::first { $_ > 5 } @numbers;

=head1 DESCRIPTION

Are you sick of trying to remember whether a particular helper is defined in
L<List::Util>, L<List::SomeUtils> or L<List::UtilsBy>? I sure am. Now you
don't have to remember. This module will export all of the functions that
either of those three modules defines.

Note that all function documentation has been shamelessly copied from
L<List::Util>, L<List::SomeUtils> and L<List::UtilsBy>.

=head2 Which One Wins?

Recently, L<List::Util> has started including some of the subs that used to
only be in L<List::SomeUtils>. Similarly, L<List::SomeUtils> has some small
overlap with L<List::UtilsBy>.

C<List::AllUtils> use to always favors the subroutine provided by
L<List::Util>, L<List::SomeUtils> or L<List::UtilsBy> in that order. However,
as of L<List::Util> 1.56, it included some functions, C<mesh> and C<zip> with
the same name as L<List::SomeUtils> functions, but different behavior.

So going forward, we will always prefer backwards compatibility. This means
that C<mesh> and C<zip> will always come from L<List::SomeUtils>. If other
incompatible functions are added to L<List::Util>, those will also be skipped
in favor of the L<List::SomeUtils> version.

The docs below come from L<List::Util> 1.56, L<List::SomeUtils> 0.58, and
L<List::UtilsBy> 0.11.

=head1 WHAT IS EXPORTED?

All this module does is load L<List::Util>, L<List::SomeUtils>, and
L<List::UtilsBy>, and then re-export everything that they provide. That means
that regardless of the documentation below, you will get any subroutine that
your installed version provides.

=head1 LIST-REDUCTION FUNCTIONS

The following set of functions all apply a given block of code to a list of
values.

=head2 reduce

    $result = reduce { BLOCK } @list

Reduces C<@list> by calling C<BLOCK> in a scalar context multiple times,
setting C<$a> and C<$b> each time. The first call will be with C<$a> and C<$b>
set to the first two elements of the list, subsequent calls will be done by
setting C<$a> to the result of the previous call and C<$b> to the next element
in the list.

Returns the result of the last call to the C<BLOCK>. If C<@list> is empty then
C<undef> is returned. If C<@list> only contains one element then that element
is returned and C<BLOCK> is not executed.

The following examples all demonstrate how C<reduce> could be used to implement
the other list-reduction functions in this module. (They are not in fact
implemented like this, but instead in a more efficient manner in individual C
functions).

    $foo = reduce { defined($a)            ? $a :
                    $code->(local $_ = $b) ? $b :
                                             undef } undef, @list # first

    $foo = reduce { $a > $b ? $a : $b } 1..10       # max
    $foo = reduce { $a gt $b ? $a : $b } 'A'..'Z'   # maxstr
    $foo = reduce { $a < $b ? $a : $b } 1..10       # min
    $foo = reduce { $a lt $b ? $a : $b } 'aa'..'zz' # minstr
    $foo = reduce { $a + $b } 1 .. 10               # sum
    $foo = reduce { $a . $b } @bar                  # concat

    $foo = reduce { $a || $code->(local $_ = $b) } 0, @bar   # any
    $foo = reduce { $a && $code->(local $_ = $b) } 1, @bar   # all
    $foo = reduce { $a && !$code->(local $_ = $b) } 1, @bar  # none
    $foo = reduce { $a || !$code->(local $_ = $b) } 0, @bar  # notall
       # Note that these implementations do not fully short-circuit

If your algorithm requires that C<reduce> produce an identity value, then make
sure that you always pass that identity value as the first argument to prevent
C<undef> being returned

  $foo = reduce { $a + $b } 0, @values;             # sum with 0 identity value

The above example code blocks also suggest how to use C<reduce> to build a
more efficient combined version of one of these basic functions and a C<map>
block. For example, to find the total length of all the strings in a list,
we could use

    $total = sum map { length } @strings;

However, this produces a list of temporary integer values as long as the
original list of strings, only to reduce it down to a single value again. We
can compute the same result more efficiently by using C<reduce> with a code
block that accumulates lengths by writing this instead as:

    $total = reduce { $a + length $b } 0, @strings

The other scalar-returning list reduction functions are all specialisations of
this generic idea.

=head2 reductions

    @results = reductions { BLOCK } @list

I<Since version 1.54.>

Similar to C<reduce> except that it also returns the intermediate values along
with the final result. As before, C<$a> is set to the first element of the
given list, and the C<BLOCK> is then called once for remaining item in the
list set into C<$b>, with the result being captured for return as well as
becoming the new value for C<$a>.

The returned list will begin with the initial value for C<$a>, followed by
each return value from the block in order. The final value of the result will
be identical to what the C<reduce> function would have returned given the same
block and list.

    reduce     { "$a-$b" }  "a".."d"    # "a-b-c-d"
    reductions { "$a-$b" }  "a".."d"    # "a", "a-b", "a-b-c", "a-b-c-d"

=head2 any

    my $bool = any { BLOCK } @list;

I<Since version 1.33.>

Similar to C<grep> in that it evaluates C<BLOCK> setting C<$_> to each element
of C<@list> in turn. C<any> returns true if any element makes the C<BLOCK>
return a true value. If C<BLOCK> never returns true or C<@list> was empty then
it returns false.

Many cases of using C<grep> in a conditional can be written using C<any>
instead, as it can short-circuit after the first true result.

    if( any { length > 10 } @strings ) {
        # at least one string has more than 10 characters
    }

Note: Due to XS issues the block passed may be able to access the outer @_
directly. This is not intentional and will break under debugger.

=head2 all

    my $bool = all { BLOCK } @list;

I<Since version 1.33.>

Similar to L</any>, except that it requires all elements of the C<@list> to
make the C<BLOCK> return true. If any element returns false, then it returns
false. If the C<BLOCK> never returns false or the C<@list> was empty then it
returns true.

Note: Due to XS issues the block passed may be able to access the outer @_
directly. This is not intentional and will break under debugger.

=head2 none

=head2 notall

    my $bool = none { BLOCK } @list;

    my $bool = notall { BLOCK } @list;

I<Since version 1.33.>

Similar to L</any> and L</all>, but with the return sense inverted. C<none>
returns true only if no value in the C<@list> causes the C<BLOCK> to return
true, and C<notall> returns true only if not all of the values do.

Note: Due to XS issues the block passed may be able to access the outer @_
directly. This is not intentional and will break under debugger.

=head2 first

    my $val = first { BLOCK } @list;

Similar to C<grep> in that it evaluates C<BLOCK> setting C<$_> to each element
of C<@list> in turn. C<first> returns the first element where the result from
C<BLOCK> is a true value. If C<BLOCK> never returns true or C<@list> was empty
then C<undef> is returned.

    $foo = first { defined($_) } @list    # first defined value in @list
    $foo = first { $_ > $value } @list    # first value in @list which
                                          # is greater than $value

=head2 max

    my $num = max @list;

Returns the entry in the list with the highest numerical value. If the list is
empty then C<undef> is returned.

    $foo = max 1..10                # 10
    $foo = max 3,9,12               # 12
    $foo = max @bar, @baz           # whatever

=head2 maxstr

    my $str = maxstr @list;

Similar to L</max>, but treats all the entries in the list as strings and
returns the highest string as defined by the C<gt> operator. If the list is
empty then C<undef> is returned.

    $foo = maxstr 'A'..'Z'          # 'Z'
    $foo = maxstr "hello","world"   # "world"
    $foo = maxstr @bar, @baz        # whatever

=head2 min

    my $num = min @list;

Similar to L</max> but returns the entry in the list with the lowest numerical
value. If the list is empty then C<undef> is returned.

    $foo = min 1..10                # 1
    $foo = min 3,9,12               # 3
    $foo = min @bar, @baz           # whatever

=head2 minstr

    my $str = minstr @list;

Similar to L</min>, but treats all the entries in the list as strings and
returns the lowest string as defined by the C<lt> operator. If the list is
empty then C<undef> is returned.

    $foo = minstr 'A'..'Z'          # 'A'
    $foo = minstr "hello","world"   # "hello"
    $foo = minstr @bar, @baz        # whatever

=head2 product

    my $num = product @list;

I<Since version 1.35.>

Returns the numerical product of all the elements in C<@list>. If C<@list> is
empty then C<1> is returned.

    $foo = product 1..10            # 3628800
    $foo = product 3,9,12           # 324

=head2 sum

    my $num_or_undef = sum @list;

Returns the numerical sum of all the elements in C<@list>. For backwards
compatibility, if C<@list> is empty then C<undef> is returned.

    $foo = sum 1..10                # 55
    $foo = sum 3,9,12               # 24
    $foo = sum @bar, @baz           # whatever

=head2 sum0

    my $num = sum0 @list;

I<Since version 1.26.>

Similar to L</sum>, except this returns 0 when given an empty list, rather
than C<undef>.

=head1 KEY/VALUE PAIR LIST FUNCTIONS

The following set of functions, all inspired by L<List::Pairwise>, consume an
even-sized list of pairs. The pairs may be key/value associations from a hash,
or just a list of values. The functions will all preserve the original ordering
of the pairs, and will not be confused by multiple pairs having the same "key"
value - nor even do they require that the first of each pair be a plain string.

B<NOTE>: At the time of writing, the following C<pair*> functions that take a
block do not modify the value of C<$_> within the block, and instead operate
using the C<$a> and C<$b> globals instead. This has turned out to be a poor
design, as it precludes the ability to provide a C<pairsort> function. Better
would be to pass pair-like objects as 2-element array references in C<$_>, in
a style similar to the return value of the C<pairs> function. At some future
version this behaviour may be added.

Until then, users are alerted B<NOT> to rely on the value of C<$_> remaining
unmodified between the outside and the inside of the control block. In
particular, the following example is B<UNSAFE>:

 my @kvlist = ...

 foreach (qw( some keys here )) {
    my @items = pairgrep { $a eq $_ } @kvlist;
    ...
 }

Instead, write this using a lexical variable:

 foreach my $key (qw( some keys here )) {
    my @items = pairgrep { $a eq $key } @kvlist;
    ...
 }

=head2 pairs

    my @pairs = pairs @kvlist;

I<Since version 1.29.>

A convenient shortcut to operating on even-sized lists of pairs, this function
returns a list of C<ARRAY> references, each containing two items from the
given list. It is a more efficient version of

    @pairs = pairmap { [ $a, $b ] } @kvlist

It is most convenient to use in a C<foreach> loop, for example:

    foreach my $pair ( pairs @kvlist ) {
       my ( $key, $value ) = @$pair;
       ...
    }

Since version C<1.39> these C<ARRAY> references are blessed objects,
recognising the two methods C<key> and C<value>. The following code is
equivalent:

    foreach my $pair ( pairs @kvlist ) {
       my $key   = $pair->key;
       my $value = $pair->value;
       ...
    }

Since version C<1.51> they also have a C<TO_JSON> method to ease
serialisation.

=head2 unpairs

    my @kvlist = unpairs @pairs

I<Since version 1.42.>

The inverse function to C<pairs>; this function takes a list of C<ARRAY>
references containing two elements each, and returns a flattened list of the
two values from each of the pairs, in order. This is notionally equivalent to

    my @kvlist = map { @{$_}[0,1] } @pairs

except that it is implemented more efficiently internally. Specifically, for
any input item it will extract exactly two values for the output list; using
C<undef> if the input array references are short.

Between C<pairs> and C<unpairs>, a higher-order list function can be used to
operate on the pairs as single scalars; such as the following near-equivalents
of the other C<pair*> higher-order functions:

    @kvlist = unpairs grep { FUNC } pairs @kvlist
    # Like pairgrep, but takes $_ instead of $a and $b

    @kvlist = unpairs map { FUNC } pairs @kvlist
    # Like pairmap, but takes $_ instead of $a and $b

Note however that these versions will not behave as nicely in scalar context.

Finally, this technique can be used to implement a sort on a keyvalue pair
list; e.g.:

    @kvlist = unpairs sort { $a->key cmp $b->key } pairs @kvlist

=head2 pairkeys

    my @keys = pairkeys @kvlist;

I<Since version 1.29.>

A convenient shortcut to operating on even-sized lists of pairs, this function
returns a list of the the first values of each of the pairs in the given list.
It is a more efficient version of

    @keys = pairmap { $a } @kvlist

=head2 pairvalues

    my @values = pairvalues @kvlist;

I<Since version 1.29.>

A convenient shortcut to operating on even-sized lists of pairs, this function
returns a list of the the second values of each of the pairs in the given list.
It is a more efficient version of

    @values = pairmap { $b } @kvlist

=head2 pairgrep

    my @kvlist = pairgrep { BLOCK } @kvlist;

    my $count = pairgrep { BLOCK } @kvlist;

I<Since version 1.29.>

Similar to perl's C<grep> keyword, but interprets the given list as an
even-sized list of pairs. It invokes the C<BLOCK> multiple times, in scalar
context, with C<$a> and C<$b> set to successive pairs of values from the
C<@kvlist>.

Returns an even-sized list of those pairs for which the C<BLOCK> returned true
in list context, or the count of the B<number of pairs> in scalar context.
(Note, therefore, in scalar context that it returns a number half the size of
the count of items it would have returned in list context).

    @subset = pairgrep { $a =~ m/^[[:upper:]]+$/ } @kvlist

As with C<grep> aliasing C<$_> to list elements, C<pairgrep> aliases C<$a> and
C<$b> to elements of the given list. Any modifications of it by the code block
will be visible to the caller.

=head2 pairfirst

    my ( $key, $val ) = pairfirst { BLOCK } @kvlist;

    my $found = pairfirst { BLOCK } @kvlist;

I<Since version 1.30.>

Similar to the L</first> function, but interprets the given list as an
even-sized list of pairs. It invokes the C<BLOCK> multiple times, in scalar
context, with C<$a> and C<$b> set to successive pairs of values from the
C<@kvlist>.

Returns the first pair of values from the list for which the C<BLOCK> returned
true in list context, or an empty list of no such pair was found. In scalar
context it returns a simple boolean value, rather than either the key or the
value found.

    ( $key, $value ) = pairfirst { $a =~ m/^[[:upper:]]+$/ } @kvlist

As with C<grep> aliasing C<$_> to list elements, C<pairfirst> aliases C<$a> and
C<$b> to elements of the given list. Any modifications of it by the code block
will be visible to the caller.

=head2 pairmap

    my @list = pairmap { BLOCK } @kvlist;

    my $count = pairmap { BLOCK } @kvlist;

I<Since version 1.29.>

Similar to perl's C<map> keyword, but interprets the given list as an
even-sized list of pairs. It invokes the C<BLOCK> multiple times, in list
context, with C<$a> and C<$b> set to successive pairs of values from the
C<@kvlist>.

Returns the concatenation of all the values returned by the C<BLOCK> in list
context, or the count of the number of items that would have been returned in
scalar context.

    @result = pairmap { "The key $a has value $b" } @kvlist

As with C<map> aliasing C<$_> to list elements, C<pairmap> aliases C<$a> and
C<$b> to elements of the given list. Any modifications of it by the code block
will be visible to the caller.

See L</KNOWN BUGS> for a known-bug with C<pairmap>, and a workaround.

=head1 OTHER FUNCTIONS

=head2 shuffle

    my @values = shuffle @values;

Returns the values of the input in a random order

    @cards = shuffle 0..51      # 0..51 in a random order

This function is affected by the C<$RAND> variable.

=head2 sample

    my @items = sample $count, @values

I<Since version 1.54.>

Randomly select the given number of elements from the input list. Any given
position in the input list will be selected at most once.

If there are fewer than C<$count> items in the list then the function will
return once all of them have been randomly selected; effectively the function
behaves similarly to L</shuffle>.

This function is affected by the C<$RAND> variable.

=head2 uniq

    my @subset = uniq @values

I<Since version 1.45.>

Filters a list of values to remove subsequent duplicates, as judged by a
DWIM-ish string equality or C<undef> test. Preserves the order of unique
elements, and retains the first value of any duplicate set.

    my $count = uniq @values

In scalar context, returns the number of elements that would have been
returned as a list.

The C<undef> value is treated by this function as distinct from the empty
string, and no warning will be produced. It is left as-is in the returned
list. Subsequent C<undef> values are still considered identical to the first,
and will be removed.

=head2 uniqint

    my @subset = uniqint @values

I<Since version 1.55.>

Filters a list of values to remove subsequent duplicates, as judged by an
integer numerical equality test. Preserves the order of unique elements, and
retains the first value of any duplicate set. Values in the returned list will
be coerced into integers.

    my $count = uniqint @values

In scalar context, returns the number of elements that would have been
returned as a list.

Note that C<undef> is treated much as other numerical operations treat it; it
compares equal to zero but additionally produces a warning if such warnings
are enabled (C<use warnings 'uninitialized';>). In addition, an C<undef> in
the returned list is coerced into a numerical zero, so that the entire list of
values returned by C<uniqint> are well-behaved as integers.

=head2 uniqnum

    my @subset = uniqnum @values

I<Since version 1.44.>

Filters a list of values to remove subsequent duplicates, as judged by a
numerical equality test. Preserves the order of unique elements, and retains
the first value of any duplicate set.

    my $count = uniqnum @values

In scalar context, returns the number of elements that would have been
returned as a list.

Note that C<undef> is treated much as other numerical operations treat it; it
compares equal to zero but additionally produces a warning if such warnings
are enabled (C<use warnings 'uninitialized';>). In addition, an C<undef> in
the returned list is coerced into a numerical zero, so that the entire list of
values returned by C<uniqnum> are well-behaved as numbers.

Note also that multiple IEEE C<NaN> values are treated as duplicates of
each other, regardless of any differences in their payloads, and despite
the fact that C<< 0+'NaN' == 0+'NaN' >> yields false.

=head2 uniqstr

    my @subset = uniqstr @values

I<Since version 1.45.>

Filters a list of values to remove subsequent duplicates, as judged by a
string equality test. Preserves the order of unique elements, and retains the
first value of any duplicate set.

    my $count = uniqstr @values

In scalar context, returns the number of elements that would have been
returned as a list.

Note that C<undef> is treated much as other string operations treat it; it
compares equal to the empty string but additionally produces a warning if such
warnings are enabled (C<use warnings 'uninitialized';>). In addition, an
C<undef> in the returned list is coerced into an empty string, so that the
entire list of values returned by C<uniqstr> are well-behaved as strings.

=head2 head

    my @values = head $size, @list;

I<Since version 1.50.>

Returns the first C<$size> elements from C<@list>. If C<$size> is negative, returns
all but the last C<$size> elements from C<@list>.

    @result = head 2, qw( foo bar baz );
    # foo, bar

    @result = head -2, qw( foo bar baz );
    # foo

=head2 tail

    my @values = tail $size, @list;

I<Since version 1.50.>

Returns the last C<$size> elements from C<@list>. If C<$size> is negative, returns
all but the first C<$size> elements from C<@list>.

    @result = tail 2, qw( foo bar baz );
    # bar, baz

    @result = tail -2, qw( foo bar baz );
    # baz

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

Makes a copy of the list and then passes each element I<from the copy> to the
BLOCK. Any changes or assignments to C<$_> in the BLOCK will only affect the
elements of the new list. However, if C<$_> is a reference then changes to the
referenced value will be seen in both the original and new list.

This function is similar to C<map> but will not modify the elements of the
input list:

  my @list = (1 .. 4);
  my @mult = apply { $_ *= 2 } @list;
  print "\@list = @list\n";
  print "\@mult = @mult\n";
  __END__
  @list = 1 2 3 4
  @mult = 2 4 6 8

Think of it as syntactic sugar for

  for (my @mult = @list) { $_ *= 2 }

Note that you must alter C<$_> directly inside BLOCK in order for changes to
make effect. New value returned from the BLOCK are ignored:

  # @new is identical to @list.
  my @new = apply { $_ * 2 } @list;

  # @new is different from @list
  my @new = apply { $_ =* 2 } @list;

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
  my @part = part { $idx[$i++ % 3] } 1 .. 8; # [1, 4, 7], [2, 3, 5, 6, 8]

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

This function returns a list in list context. In scalar context it returns a
count indicating the number of modes in the list.

=head1 List::UtilsBy FUNCTIONS

All functions added since version 0.04 unless otherwise stated, as the
original names for earlier versions were renamed.

=head2 sort_by

   @vals = sort_by { KEYFUNC } @vals

Returns the list of values sorted according to the string values returned by
the C<KEYFUNC> block or function. A typical use of this may be to sort objects
according to the string value of some accessor, such as

   sort_by { $_->name } @people

The key function is called in scalar context, being passed each value in turn
as both C<$_> and the only argument in the parameters, C<@_>. The values are
then sorted according to string comparisons on the values returned.

This is equivalent to

   sort { $a->name cmp $b->name } @people

except that it guarantees the C<name> accessor will be executed only once per
value.

One interesting use-case is to sort strings which may have numbers embedded in
them "naturally", rather than lexically.

   sort_by { s/(\d+)/sprintf "%09d", $1/eg; $_ } @strings

This sorts strings by generating sort keys which zero-pad the embedded numbers
to some level (9 digits in this case), helping to ensure the lexical sort puts
them in the correct order.

=head2 nsort_by

   @vals = nsort_by { KEYFUNC } @vals

Similar to L</sort_by> but compares its key values numerically.

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

I<Since version 0.11.>

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

I<Since version 0.07.>

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

I<Since version 0.09.>

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

I<Since version 0.05.>

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

I<Since version 0.10.>

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

I<Since version 0.07.>

Returns the list of values shuffled into a random order. The randomisation is
not uniform, but weighted by the value returned by the C<WEIGHTFUNC>. The
probabilty of each item being returned first will be distributed with the
distribution of the weights, and so on recursively for the remaining items.

=head2 bundle_by

   @vals = bundle_by { BLOCKFUNC } $number, @vals

I<Since version 0.07.>

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

Bugs may be submitted at L<https://github.com/houseabsolute/List-AllUtils/issues>.

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
button at L<https://www.urth.org/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Andy Jack Dave Jacoby Karen Etheridge Olaf Alders Ricardo Signes Yanick Champoux

=over 4

=item *

Andy Jack <github@veracity.ca>

=item *

Dave Jacoby <jacoby.david@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
