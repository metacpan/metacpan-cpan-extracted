=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Iterator::Util - Essential utilities for the Iterator class.

=head1 VERSION

This documentation describes version 0.02 of Iterator::Util, August 23, 2005.

=cut

use strict;
use warnings;
package Iterator::Util;
our $VERSION = '0.02';

use base 'Exporter';
use vars qw/@EXPORT @EXPORT_OK %EXPORT_TAGS/;

@EXPORT  = qw(imap igrep irange ilist iarray ihead iappend
              ipairwise iskip iskip_until imesh izip iuniq);

@EXPORT_OK   = (@EXPORT);

use Iterator;

# Function name: imap
# Synopsis:      $iter = imap {code} $another_iterator;
# Description:   Transforms an iterator.
# Created:       07/27/2005 by EJR
# Parameters:    code - Transformation code
#                $another_iterator - any other iterator.
# Returns:       Transformed iterator.
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::Am_Now_Exhausted
sub imap (&$)
{
    my ($transformation, $iter) = @_;

    Iterator::X::Parameter_Error->throw(q{Argument to imap must be an Iterator object})
        unless UNIVERSAL::isa($iter, 'Iterator');

    return Iterator->new( sub
    {
        Iterator::is_done if ($iter->is_exhausted);

        local $_ = $iter->value ();
        return $transformation-> ();
    });
}


# Function name: igrep
# Synopsis:      $iter = igrep {code} $another_iterator;
# Description:   Filters an iterator.
# Created:       07/27/2005 by EJR
# Parameters:    code - Filter condition.
#                $another_iterator - any other iterator.
# Returns:       Filtered iterator.
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::Am_Now_Exhausted
sub igrep (&$)
{
    my ($test, $iter) = @_;

    Iterator::X::Parameter_Error->throw(q{Argument to imap must be an Iterator object})
        unless UNIVERSAL::isa($iter, 'Iterator');

    return Iterator->new(sub
    {
        while ($iter->isnt_exhausted ())
        {
            local $_ = $iter->value ();
            return $_ if $test-> ();
        }

        Iterator::is_done();
    });
}


# Function name: irange
# Synopsis:      $iter = irange ($start, $end, $step);
# Description:   Generates an arithmetic sequence of numbers.
# Created:       07/27/2005 by EJR
# Parameters:    $start - First value.
#                $end   - Final value.     (may be omitted)
#                $step  - Increment value. (may be omitted)
# Returns:       Sequence iterator
# Exceptions:    Iterator::X::Am_Now_Exhausted
# Notes:         If the $end value is omitted, iterator is unbounded.
#                If $step is omitted, it defaults to 1.
#                $step may be negative (or even zero).
sub irange
{
    my ($from, $to, $step) = @_;
    $step = 1 unless defined $step;

    return Iterator->new (sub
    {
        # Reached limit?
        Iterator::is_done
                if (defined($to)
                    &&  ($step>0 && $from>$to  ||  $step<0 && $from<$to) );

        # This iteration's return value
        my $retval = $from;

        $from += $step;
        return $retval;
    });
}

# Function name: ilist
# Synopsis:      $iter = ilist (@list);
# Description:   Creates an iterator from a list
# Created:       07/28/2005 by EJR
# Parameters:    @list - list of values to iterate over
# Returns:       Array (list) iterator
# Exceptions:    Iterator::X::Am_Now_Exhausted
# Notes:         Makes an internal copy of the list.
sub ilist
{
    my @items = @_;
    my $index=0;
    return Iterator->new( sub
    {
        Iterator::is_done if ($index >= @items);
        return $items[$index++];
    });
}

# Function name: iarray
# Synopsis:      $iter = iarray ($a_ref);
# Description:   Creates an iterator from an array reference
# Created:       07/28/2005 by EJR
# Parameters:    $a_ref - Reference to array to iterate over
# Returns:       Array iterator
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::Am_Now_Exhausted
# Notes:         Does not make an internal copy of the list.
sub iarray ($)
{
    my $items = shift;
    my $index=0;

    Iterator::X::Parameter_Error->throw->
        (q{Argument to iarray must be an array reference})
            if ref $items ne 'ARRAY';

    return Iterator->new( sub
    {
        Iterator::is_done if $index >= @$items;
        return $items->[$index++];
    });
}

# Function name: ihead
# Synopsis:      $iter = ihead ($num, $some_other_iterator);
# Synopsis:      @valuse = ihead ($num, $iterator);
# Description:   Returns at most $num items from other iterator.
# Created:       07/28/2005 by EJR
#                08/02/2005 EJR: combined with ahead, per Will Coleda
# Parameters:    $num - Max number of items to return
#                $some_other_iterator - another iterator
# Returns:       limited iterator
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::Am_Now_Exhausted
sub ihead
{
    my $num  = shift;
    my $iter = shift;

    Iterator::X::Parameter_Error->throw
        (q{Second parameter for ihead must be an Iterator})
            unless UNIVERSAL::isa($iter, 'Iterator');

    # List context?  Return the first $num elements.
    if (wantarray)
    {
        my @a;
        while ($iter->isnt_exhausted  &&  (!defined($num)  ||  $num-- > 0))
        {
            push @a, $iter->value;
        }
        return @a;
    }

    # Scalar context: return an iterator to return at most $num elements.
    return Iterator->new(sub
    {
        Iterator::is_done if $num <= 0;

        $num--;
        return $iter->value;
    });
}

# Function name: iappend
# Synopsis:      $iter = iappend (@iterators);
# Description:   Joins a bunch of iterators together.
# Created:       07/28/2005 by EJR
# Parameters:    @iterators - any number of other iterators
# Returns:       A "merged" iterator.
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::Am_Now_Exhausted
sub iappend
{
    my @its = @_;

    # Check types
    foreach (@its)
    {
        Iterator::X::Parameter_Error->throw
            (q{All parameters for iarray must be Iterators})
                unless UNIVERSAL::isa($_, 'Iterator');
    }

    # Passthru, if there's only one.
    return $its[0] if @its == 1;

    return Iterator->new (sub
    {
        my $val;

        # Any empty iterators at front of list?  Remove'em.
        while (@its  &&  $its[0]->is_exhausted)
        {
            shift @its;
        }

        # No more iterators?  Then we're done.
        Iterator::is_done
            if @its == 0;

        # Return the next value of the iterator at the head of the list.
        return $its[0]->value;
    });
}

# Function name: ipairwise
# Synopsis:      $iter = ipairwise {code} ($iter1, $iter2);
# Description:   Applies an operation to pairs of values from iterators.
# Created:       07/28/2005 by EJR
# Parameters:    code - transformation, may use $a and $b
#                $iter1 - First iterator; "$a" value.
#                $iter2 - First iterator; "$b" value.
# Returns:       Iterator
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::Am_Now_Exhausted
sub ipairwise (&$$)
{
    my $op    = shift;
    my $iterA = shift;
    my $iterB = shift;

    # Check types
    for ($iterA, $iterB)
    {
        Iterator::X::Parameter_Error->throw
            (q{Second and third parameters for ipairwise must be Iterators})
                unless UNIVERSAL::isa($_, 'Iterator');
    }

    return Iterator->new(sub
    {
        Iterator::is_done
            if $iterA->is_exhausted  ||  $iterB->is_exhausted;

        # Localize $a and $b
        # My thanks to Benjamin Goldberg for this little bit of evil.
        my ($caller_a, $caller_b) = do
        {
            my $pkg;
            my $i = 1;
            while (1)
            {
                $pkg = caller($i++);
                last if $pkg ne 'Iterator'  &&  $pkg ne 'Iterator::Util';
            }
            no strict 'refs';
            \*{$pkg.'::a'}, \*{$pkg.'::b'};
        };

        # Set caller's $a and $b
        local (*$caller_a, *$caller_b) = \($iterA->value, $iterB->value);

        # Invoke caller's operation
        return $op->();
    });
}

# Function name: iskip
# Synopsis:      $iter = iskip $num, $another_iterator
# Description:   Skips the first $num values of another iterator
# Created:       07/28/2005 by EJR
# Parameters:    $num - how many values to skip
#                $another_iterator - another iterator
# Returns:       Sequence iterator
# Exceptions:    None
sub iskip
{
    my $num = shift;
    my $it  = shift;

    Iterator::X::Parameter_Error->throw
        (q{Second parameter for iskip must be an Iterator})
            unless UNIVERSAL::isa($it, 'Iterator');

    # Discard first $num values
    $it->value  while $it->isnt_exhausted  &&  $num-->0;

    return $it;
}


# Function name: iskip_until
# Synopsis:      $iter = iskip_until {code}, $another_iterator
# Description:   Skips values of another iterator until {code} is true.
# Created:       07/28/2005 by EJR
# Parameters:    {code} - Determines when to start returning values
#                $another_iterator - another iterator
# Returns:       Sequence iterator
# Exceptions:    Iterator::X::Am_Now_Exhausted
sub iskip_until (&$)
{
    my $code = shift;
    my $iter = shift;
    my $value;
    my $found_it = 0;

    Iterator::X::Parameter_Error->throw
        (q{Second parameter for iskip_until must be an Iterator})
            unless UNIVERSAL::isa($iter, 'Iterator');

    # Discard first $num values
    while ($iter->isnt_exhausted)
    {
        local $_ = $iter->value;
        if ($code->())
        {
            $found_it = 1;
            $value = $_;
            last;
        }
    }

    # Didn't find it?  Pity.
    Iterator::is_done
        unless $found_it;

    # Return an iterator with this value, and all remaining values.
    return iappend ilist($value), $iter;
}


# Function name: imesh / izip
# Synopsis:      $iter = imesh ($iter1, $iter2, ...)
# Description:   Merges other iterators together.
# Created:       07/30/2005 by EJR
# Parameters:    Any number of other iterators.
# Returns:       Sequence iterator
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::Am_Now_Exhausted
foreach my $sub (qw/imesh izip/)
{
    no strict 'refs';
    *$sub = sub
    {
        use strict 'refs';

        my @iterators = @_;
        my $it_index  = 0;

        foreach my $iter (@iterators)
        {
            Iterator::X::Parameter_Error->throw(
                "Argument to $sub is not an iterator")
                unless UNIVERSAL::isa($iter, 'Iterator');
        }

        return Iterator->new (sub
        {
            Iterator::is_done
                if $iterators[$it_index]->is_exhausted();

            my $retval = $iterators[$it_index]->value();

            if (++$it_index >= @iterators)
            {
                $it_index = 0;
            }

            return $retval;
        });
    };
}

# Function name: iuniq
# Synopsis:      $iter = iuniq ($another_iterator);
# Description:   Removes duplicate entries from an iterator.
# Created:       07/30/2005 by EJR
# Parameters:    Another iterator.
# Returns:       Sequence iterator
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::Am_Now_Exhausted
sub iuniq
{
    Iterator::X::Parameter_Error->throw ("Too few parameters to iuniq")
        if @_ < 1;
    Iterator::X::Parameter_Error->throw ("Too many parameters to iuniq")
        if @_ > 1;

    my $iter = shift;
    Iterator::X::Parameter_Error->throw("Argument to iuniq is not an iterator")
        unless UNIVERSAL::isa($iter, 'Iterator');

    my %did_see;
    return Iterator->new (sub
    {
        my $value;
        while (1)
        {
            Iterator::is_done
                if $iter->is_exhausted;

            $value = $iter->value;
            last if !$did_see{$value}++;
        }
        return $value;
    });
}

1;
__END__

=head1 SYNOPSIS

 use Iterator::Util;

 # Transform sequences
 $iterator = imap { transformation code } $some_other_iterator;

 # Filter sequences
 $iterator = igrep { condition code } $some_other_iterator;

 # Range of values  (arithmetic sequence)
 $iter = irange ($start, $end, $increment);
 $iter = irange ($start, $end);
 $iter = irange ($start);

 # Iterate over an arbitrary list
 $iter = ilist (item, item, ...);
 $iter = ilist (@items);

 # Iterate over an array, by reference
 $iter = iarray (\@array);

 # Return at most $num items from an iterator
 $iter   = ihead ($num, $some_other_iterator);
 @values = ihead ($num, $some_other_iterator);

 # Append multiple iterators into one
 $iter = iappend ($it1, $it2, $it3, ...);

 # Apply a function to pairs of iterator values
 $iter = ipairwise {code} $iter_A, $iter_B;

 # Skip the first $num values of an iterator
 $iter = iskip ($num, $some_other_iterator);

 # Skip values from an iterator until a condition is met
 $iter = iskip_until {code} $some_other_iterator;

 # Mesh iterators together
 $iter = imesh ($iter, $iter, ...);
 $iter = izip  ($iter, $iter, ...);

 # Return each value of an iterator once
 $iter = iuniq ($another_iterator);

=head1 DESCRIPTION

This module implements many useful functions for creating and
manipulating iterator objects.

An "iterator" is an object, represented as a code block that generates
the "next value" of a sequence, and generally implemented as a
closure.  For further information, including a tutorial on using
iterator objects, see the L<Iterator> documentation.

=head1 FUNCTIONS

=over 4

=item imap

 $iter = imap { transformation code } $some_other_iterator;

Returns an iterator that is a transformation of some other iterator.
Within the transformation code, C<$_> is set to each value of the
other iterator, in turn.

I<Examples:>

 $evens   = imap { $_ * 2  }  irange (0);  # returns 0, 2, 4, ...
 $squares = imap { $_ * $_ }  irange (7);  # 49, 64, 81, 100, ...

=item igrep

 $iter = igrep { condition } $some_other_iterator;

Returns an iterator that selectively returns values from some other
iterator.  Within the C<condition> code, C<$_> is set to each value of
the other iterator, in turn.

I<Examples:>

 $fives = igrep { $_ % 5 == 0 } irange (0,10);   # returns 0, 5, 10
 $small = igrep { $_ < 10 }     irange (8,12);   # returns 8, 9

=item irange

 $iter = irange ($start, $end, $increment);
 $iter = irange ($start, $end);
 $iter = irange ($start);

C<irange> returns a sequence of numbers.  The sequence begins with
C<$start>, ends at C<$end>, and steps by C<$increment>.  This is sort
of the Iterator version of a C<for> loop.

If C<$increment> is not specified, 1 is used.  C<$increment> may be
negative -- or even zero, in which case iterator returns an infinite
sequence of C<$start>.

If C<$end> is not specified (is C<undef>), the sequence is infinite.

I<Examples:>

 $iter = irange (1, 2);           #  Iterate from 1 to 2
 $val  = $iter->value();          #  $val is now 1.
 $val  = $iter->value();          #  $val is now 2.
 $bool = $iter->is_exhausted();   #  $bool is now true.

 $iter = irange (10, 8, -1);      #  Iterate from 10 down to 8
 $iter = irange (1);              #  Iterate from 1, endlessly.

=item ilist

 $iter = ilist (@items);

Returns an iterator that iterates over an arbitrary sequence of
values.  It's sort of an Iterator version of C<foreach>.

This function makes an internal copy of the list, so it may not be
appropriate for an extremely large list.

I<Example:>

 $iter = ilist (4, 'minus five', @foo, 7);
 $val  = $iter->value();          # $val is now 4
 $val  = $iter->value();          # $val is now 'minus five'
 ...

=item iarray

 $iter = iarray (\@array);

Returns an iterator that iterates over an array.  Note that since it
uses a reference to that array, if you modify the array, that will be
reflected in the values returned by the iterator.  This may be What
You Want.  Or it may cause Hard-To-Find Bugs.

=item ihead

 $iter   = ihead ($num, $some_other_iterator);
 @values = ihead ($num, $some_iterator);

In scalar context, creates an iterator that returns at most C<$num>
items from another iterator, then stops.

In list context, returns the first C<$num> items from the iterator.
If C<$num> is C<undef>, all remaining values are pulled
from the iterator until it is exhausted.  Use C<undef> with caution;
iterators can be huge -- or infinite.

I<Examples:>

 $iota5 = ihead 5, irange 1;    # returns 1, 2, 3, 4, 5.

 $iter = irange 1;            # infinite sequence, starting with 1
 @vals = ihead (5, $iter);    # @vals is (1, 2, 3, 4, 5)
 $nextval = $iter->value;     # $nextval is 6.

=item iappend

 $iter = iappend (@list_of_iterators);

Creates an iterator that consists of any number of other iterators
glued together.  The resulting iterator pulls values from the first
iterator until it's exhausted, then from the second, and so on.

=item ipairwise

 $iter = ipairwise {code} $it_A, $it_B;

Creates a new iterator which applies C<{code}> to pairs of elements of
two other iterators, C<$it_A> and C<$it_B> in turn.  The pairs are
assigned to C<$a> and C<$b> before invoking the code.

The new iterator is exhausted when either C<$it_A> or C<$it_B> are
exhausted.

This function is analogous to the L<pairwise|List::MoreUtils/pairwise>
function from L<List::MoreUtils>.

I<Example:>

 $first  = irange 1;                              # 1,  2,  3,  4, ...
 $second = irange 4, undef, 2;                    # 4,  6,  8, 10, ...
 $third  = ipairwise {$a * $b} $first, $second;   # 4, 12, 24, 40, ...

=item iskip

 $iter = iskip ($num, $another_iterator);

Returns an iterator that contains the values of C<$another_iterator>,
minus the first C<$num> values.  In other words, skips the first
C<$num> values of C<$another_iterator>.

I<Example:>

 $iter = ilist (24, -1, 7, 8);        # Bunch of random values
 $cdr  = iskip 1, $iter;              # "pop" the first value
 $val  = $cdr->value();               # $val is -1.

=item iskip_until

 $iter = iskip_until {code} $another_iterator;

Returns an iterator that skips the leading values of C<$another_iterator>
until C<{code}> evaluates to true for one of its values.  C<{code}>
can refer to the current value as C<$_>.

I<Example:>

 $iter = iskip_until {$_ > 5}  irange 1;    # returns 6, 7, 8, 9, ...

=item imesh

=item izip

 $iter = imesh ($iter1, $iter2, ...);

This iterator accepts any number of other iterators, and "meshes"
their values together.  First it returns the first value of the first
iterator, then the first value of the second iterator, and so on,
until it has returned the first value of all of its iterator
arguments.  Then it goes back and returns the second value of the
first iterator, and so on.  It stops when any of its iterator
arguments is exhausted.

I<Example:>

 $i1 = ilist ('a', 'b', 'c');
 $i2 = ilist (1, 2, 3);
 $i3 = ilist ('rock', 'paper', 'scissors');
 $iter = imesh ($i1, $i2, $i3);
 # $iter will return, in turn, 'a', 1, 'rock', 'b', 2, 'paper', 'c',...

C<izip> is a synonym for C<imesh>.

=item iuniq

 $iter = iuniq ($another_iterator);

Creates an iterator to return unique values from another iterator;
weeds out duplicates.

I<Example:>

 $iter = ilist (1, 2, 2, 3, 1, 4);
 $uniq = iuniq ($iter);            # returns 1, 2, 3, 4.

=back

=head1 EXPORTS

All function names are exported to the caller's namespace by default.

=head1 DIAGNOSTICS

Iterator::Util uses L<Exception::Class> objects for throwing
exceptions.  If you're not familiar with Exception::Class, don't
worry; these exception objects work just like C<$@> does with C<die>
and C<croak>, but they are easier to work with if you are trapping
errors.

See the L<Iterator|Iterator/DIAGNOSTICS> module documentation for more
information on trapping and handling these exceptions.

=over 4

=item * Parameter Errors

Class: C<Iterator::X::Parameter_Error>

You called an Iterator method with one or more bad parameters.  Since
this is almost certainly a coding error, there is probably not much
use in handling this sort of exception.

As a string, this exception provides a human-readable message about
what the problem was.

=item * Exhausted Iterators

Class: C<Iterator::X::Exhausted>

You called C<value|Iterator/value> on an iterator that is exhausted;
that is, there are no more values in the sequence to return.

As a string, this exception is "Iterator is exhausted."

=item * User Code Exceptions

Class: C<Iterator::X::User_Code_Error>

This exception is thrown when the sequence generation code throws any
sort of error besides C<Am_Now_Exhausted>.  This could be because your
code explicitly threw an error (that is, C<die>d), or because it
otherwise encountered an exception (any runtime error).

This exception has one method, C<eval_error>, which returns the
original C<$@> that was trapped by the Iterator object.  This may be a
string or an object, depending on how C<die> was invoked.

As a string, this exception evaluates to the stringified C<$@>.

=item * I/O Errors

Class: C<Iterator::X::IO_Error>

This exception is thrown when any sort of I/O error occurs; this
only happens with the filesystem iterators.

This exception has one method, C<os_error>, which returns the original
C<$!> that was trapped by the Iterator object.

As a string, this exception provides some human-readable information
along with C<$!>.

=item * Internal Errors

Class: C<Iterator::X::Internal_Error>

Something happened that I thought couldn't possibly happen.  I would
appreciate it if you could send me an email message detailing the
circumstances of the error.

=back

=head1 REQUIREMENTS

Requires the following additional modules:

L<Iterator>

=head1 SEE ALSO

I<Higher Order Perl>, Mark Jason Dominus, Morgan Kauffman 2005.

L<http://perl.plover.com/hop/>

=head1 THANKS

Much thanks to Will Coleda and Paul Lalli (and the RPI lily crowd in
general) for suggestions for the pre-release version.

=head1 AUTHOR / COPYRIGHT

Eric J. Roode, roode@cpan.org

Copyright (c) 2005 by Eric J. Roode.  All Rights Reserved.
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

To avoid my spam filter, please include "Perl", "module", or this
module's name in the message's subject line, and/or GPG-sign your
message.

=cut

=begin gpg

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.1 (Cygwin)

iD8DBQFDC5UFY96i4h5M0egRApNiAJ9WwoZql+2DE+RsSA6koGLZPcbQZACfY248
VoKah+WAFOvk46vOcn+hL9Y=
=aOws
-----END PGP SIGNATURE-----

=end gpg
