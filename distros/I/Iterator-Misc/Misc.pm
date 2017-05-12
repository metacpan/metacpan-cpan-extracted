=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Iterator::Misc - Miscellaneous iterator functions.

=head1 VERSION

This documentation describes version 0.03 of Iterator::Misc, August 26, 2005.

=cut

use strict;
use warnings;
package Iterator::Misc;
our $VERSION = '0.03';

use base 'Exporter';
use vars qw/@EXPORT @EXPORT_OK %EXPORT_TAGS/;

@EXPORT      = qw(ipermute igeometric inth irand_nth ifibonacci);
@EXPORT_OK   = @EXPORT;

use Iterator;

# Function name: ipermute
# Synopsis:      $iter = ipermute (@items);
# Description:   Generates permutations of a list.
# Created:       07/29/2005 by EJR
# Parameters:    @items - the items to be permuted.
# Returns:       Sequence iterator
# Exceptions:    Iterator::X::Am_Now_Exhausted
# Notes:         Algorithm from MJD's book.
sub ipermute
{
    my @items = @_;
    my @digits = (0) x @items;     # "Odometer".  See Dominus, pp 128-135.

    return Iterator->new (sub
    {
        unless (@digits)
        {
            Iterator::is_done;
        }

        # Use the existing state to create a new permutation
        my @perm = ();
        my @c_items = @items;
        push @perm, splice(@c_items, $_, 1)  for @digits;

        # Find the rightmost column that isn't already maximum
        my $column = $#digits;
        until ($digits[$column] < $#digits-$column || $column < 0)
            { $column-- }

        if ($column < 0)
        {
            # Last set. Generate no more.
            @digits = ();
        }
        else
        {
            # Increment the rightmost column; set colums to the right to zeroes
            $digits[$column]++;
            $digits[$_] = 0  for ($column+1 .. $#digits);
        }

        return \@perm;
    });
}


# Function name: ifibonacci
# Synopsis:      $iter = ifibonacci ($start1, $start2);
# Description:   Generates a Fibonacci sequence.
# Created:       07/27/2005 by EJR
# Parameters:    $start1 - First starting value
#                $start2 - Second starting value
# Returns:       Sequence iterator
# Exceptions:    Iterator::X::Am_Now_Exhausted
# Notes:         If $start2 is omitted, $start1 is used for both.
#                If both are omitted, 1 is used for both.
sub ifibonacci
{
    my ($start1, $start2) = @_ == 0?  (1, 1)
                          : @_ == 1?  ($_[0], $_[0])
                          : @_ == 2?  @_
                          : Iterator::X::Parameter_Error->throw
                              ("Too many arguments to ifibonacci");

    return Iterator->new( sub
    {
        my $retval;
        ($retval, $start1, $start2) = ($start1, $start2, $start1+$start2);
        return $retval;
    });
}

# Function name: igeometric
# Synopsis:      $iter = igeometric ($start, $end, $factor);
# Description:   Generates a geometric sequence.
# Created:       07/28/2005 by EJR
# Parameters:    $start - Starting value
#                $end - Ending value
#                $factor - multiplier.
# Returns:       Sequence iterator
# Exceptions:    Iterator::X::Am_Now_Exhausted
# Notes:         If $end if omitted, series is unbounded.
#                $factor must be specified.
sub igeometric
{
    my ($start, $end, $factor) = @_;
    my $growing = abs($factor) >= 1;

    return Iterator->new (sub
    {
        Iterator::is_done
            if (defined $end  &&  ($growing && $start > $end  ||  !$growing && $start < $end));

        my $retval = $start;
        $start *= $factor;
        return $retval;
    });
}

# Function name: inth
# Synopsis:      $iter = inth ($n, $iter)
# Description:   Returns 1 out of every $n items.
# Created:       07/29/2005 by EJR
# Parameters:    $n - frequency
#                $iter - other iterator
# Returns:       Sequence iterator
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::Am_Now_Exhausted
sub inth
{
    my $n1 = -1 + shift;
    my $iter = shift;

    Iterator::X::Parameter_Error->throw('Invalid "$n" value for inth')
        if $n1 < 0;

    Iterator::X::Parameter_Error->throw
        (q{Second parameter for inth must be an Iterator})
            unless UNIVERSAL::isa($iter, 'Iterator');

    return Iterator->new (sub
    {
        my $i = $n1;
        while ($i-->0  &&  $iter->isnt_exhausted)
        {
            $iter->value();   # discard value
        }

        Iterator::is_done
            if $iter->is_exhausted;

        return $iter->value();
    });
}

# Function name: irand_nth
# Synopsis:      $iter = irand_nth ($n, $iter)
# Description:   Returns 1 out of every $n items, randomly.
# Created:       07/29/2005 by EJR
# Parameters:    $n - frequency
#                $iter - other iterator
# Returns:       Sequence iterator
# Exceptions:    Iterator::X::Parameter_Error
#                Iterator::X::Am_Now_Exhausted
sub irand_nth
{
    my $n    = shift;
    my $iter = shift;

    Iterator::X::Parameter_Error->throw('Invalid "$n" value for inth')
        if $n <= 0;

    Iterator::X::Parameter_Error->throw
        (q{Second parameter for irand_nth must be an Iterator})
            unless UNIVERSAL::isa($iter, 'Iterator');

    my $prob = 1 / $n;

    return Iterator->new (sub
    {
        while (rand > $prob  &&  $iter->isnt_exhausted)
        {
            $iter->value();   # discard value
        }

        Iterator::is_done
            if $iter->is_exhausted;

        return $iter->value();
    });
}


1;
__END__

=head1 SYNOPSIS

 use Iterator::Misc;

 # Permute the elements of a list:
 $iter = ipermute (@items);

 # Select only every nth value of an iterator
 $iter = inth ($n, $another_iterator);

 # Randomly select iterator values with 1/$n probability
 $iter = irand_nth ($n, $another_iterator);

 # Fibonacci sequence
 $ifib = ifibonacci();         # default sequence starts with 1,1
 $ifib = ifibonacci($a, $b);   # or specify alternate starting pair

 # Geometric sequence
 $iter = igeometric ($start, $end, $multiplier);

=head1 DESCRIPTION

This module contains miscellaneous iterator utility functions that I
think aren't as broadly useful as the ones in L<Iterator::Util>.
They are here to keep the size of Iterator::Util down.

For more information on iterators and how to use them, see the
L<Iterator> module documentation.

=head1 FUNCTIONS

=over 4

=item ipermute

 $iter = ipermute (@list);
 $array_ref = $iter->value();

Permutes the items in an arbitrary list.  Each time the iterator is
called, it returns the next combination of the items, in the form of a
reference to an array.

I<Example:>

 $iter = ipermute ('one', 'two', 'three');
 $ref  = $iter->value();          # -> ['one', 'two', 'three']
 $ref  = $iter->value();          # -> ['one', 'three', 'two']
 $ref  = $iter->value();          # -> ['two', 'one', 'three']
 # ...etc

=item inth

 $iter = inth ($n, $another_iterator);

Returns an iterator to return every I<nth> value from the input
iterator.  The first C<$n-1> items are skipped, then one is returned,
then the next C<$n-1> items are skipped, and so on.

This can be useful for sampling data.

=item irand_nth

 $iter = irand_nth ($n, $another_iterator);

Random I<nth>.  Returns an iterator to return items from the input
iterator, with a probability of C<1/$n> for each.  On average, in the
long run, 1 of every C<$n> items will be returned.

This can be useful for random sampling of data.

=item ifibonacci

 $iter = ifibonacci ();
 $iter = ifibonacci ($start);
 $iter = ifibonacci ($start1, $start2);

Generates a Fibonacci sequence.  If starting values are not specified,
uses (1, 1).  If only one is specified, it is used for both starting
values.

=item igeometric

 $iter = igeometric ($start, $end, $multiplier)

Generates a geometric sequence.  If C<$end> is undefined, the sequence
is unbounded.

I<Examples:>

 $iter = igeometric (1, 27, 3);         # 1, 3, 9, 27.
 $iter = igeometric (1, undef, 3);      # 1, 3, 9, 27, 81, ...
 $iter = igeometric (10, undef, 0.1);   # 10, 1, 0.1, 0.01, ...

=back

=head1 EXPORTS

All function names are exported to the caller's namespace by default.

=head1 DIAGNOSTICS

Iterator::Misc uses L<Exception::Class> objects for throwing
exceptions.  If you're not familiar with Exception::Class, don't
worry; these exception objects work just like C<$@> does with C<die>
and C<croak>, but they are easier to work with if you are trapping
errors.

For more information on how to handle these exception objects,
see the L<Iterator> documentation.

=over 4

=item * Parameter Errors

Class: C<Iterator::X::Parameter_Error>

You called an Iterator::Misc function with one or more bad parameters.
Since this is almost certainly a coding error, there is probably not
much use in handling this sort of exception.

As a string, this exception provides a human-readable message about
what the problem was.

=item * Exhausted Iterators

Class: C<Iterator::X::Exhausted>

You called L<value|Iterator/value> on an iterator that is exhausted;
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

iD8DBQFDD2FyY96i4h5M0egRAgDYAJ4xaco/BbTlPFjbNbtqxiqzRyyfaACfRY9Z
e4Z3srTvcJbhykfOsEuFJHA=
=V7w+
-----END PGP SIGNATURE-----

=end gpg
