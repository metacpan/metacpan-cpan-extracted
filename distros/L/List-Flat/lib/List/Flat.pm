package List::Flat;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.003";
$VERSION = eval $VERSION;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/flat flat_r flat_f/;

# if PERL_LIST_FLAT_NO_REF_UTIL environment variable is set to a true
# value, or $List::Flat::NO_REF_UTIL is set to a true value,
# uses the pure-perl version of is_plain_arrayref.
# Otherwise, uses Ref::Util if it can be successfully loaded.

BEGIN {
    my $impl = $ENV{PERL_LIST_FLAT_NO_REF_UTIL}
      || our $NO_REF_UTIL;

    if ( !$impl && eval { require Ref::Util; 1 } ) {
        Ref::Util->import('is_plain_arrayref');
    }
    else {
        *is_plain_arrayref = sub { ref( $_[0] ) eq 'ARRAY' };
    }
}

{
    my $croak;

    sub flat {
        $croak = 1;
        goto &_flat;
        # call _flat with current @_
    }

    sub flat_r {
        undef $croak;
        goto &_flat;
        # call _flat with current @_
    }

    sub _flat {

        my @results;
        my @seens;

        # this uses @_ as the queue of items to process.
        # An item is plucked off the queue. If it's not an array ref,
        # put it in @results.

        # If it is an array ref, check to see if it's the same as any
        # of the arrayrefs we are currently in the middle of processing.
        # If it is, either croak if called as flat, or if called as
        # flat_r, don't do anything -- skip to the next one.
        # If it hasn't been seen before, put all the items it
        # contains back on the @_ queue.
        # Also, for each of the items, push a reference into @seens
        # that contains references to all the arrayrefs we are currently
        # in the middle of processing, plus this arrayref.
        # Note that @seens will be empty at the top level, so we must
        # handle both when it is empty and when it is not.

        while (@_) {

            if ( is_plain_arrayref( my $element = shift @_ ) ) {
                if ( !defined( my $seen_r = shift @seens ) ) {
                    unshift @_, @{$element};
                    unshift @seens, ( ( [$element] ) x scalar @{$element} );
                }
                ## no critic (ProhibitBooleanGrep)
                elsif ( !grep { $element == $_ } @$seen_r ) {
                    ## use critic
                   # until the recursion gets very deep, the overhead in calling
                   # List::Util::none seems to be taking more time than the
                   # additional comparisons required by grep
                    unshift @_, @{$element};
                    unshift @seens,
                      ( ( [ @$seen_r, $element ] ) x scalar @{$element} );
                }
                elsif ($croak) {
                    require Carp;
                    Carp::croak( 'Circular reference passed to '
                          . __PACKAGE__
                          . '::flat' );
                }
                     # else do nothing
            } ## tidy end: if ( is_plain_arrayref...)

            else {    # not arrayref
                shift @seens;
                push @results, $element;
            }

        } ## tidy end: while (@_)

        return wantarray ? @results : \@results;

    } ## tidy end: sub _flat

}

sub flat_f {

    # this uses @_ as the queue of items to process.
    # An item is plucked off the queue. If it's not an array ref,
    # put it in @results.
    # If it is an array ref, put its contents back in the queue.

    # Mark Jason Dominus calls this the "agenda method" of turning
    # a recursive function into an iterative one.

    my @results;

    while (@_) {

        if ( is_plain_arrayref( my $element = shift @_ ) ) {
            unshift @_, @{$element};
        }
        else {
            push @results, $element;
        }

    }

    return wantarray ? @results : \@results;

} ## tidy end: sub flat_f

1;

__END__

=encoding utf8

=head1 NAME

List::Flat - Functions to flatten a structure of array references

=head1 VERSION

This documentation refers to version 0.003

=head1 SYNOPSIS

    use List::Flat(qw/flat flat_f flat_r/);
    
    my @list = ( 1, [ 2, 3, [ 4 ], 5 ] , 6 );
    
    my @newlist = flat_f(@list);
    # ( 1, 2, 3, 4, 5, 6 )

    push @list, [ 7, \@list, 8, 9 ];
    my @newerlist = flat_r(@list);
    # ( 1, 2, 3, 4, 5, 6, 7, 8, 9 )
    
    my @evennewerlist = flat(@list);
    # throws exception
    
=head1 DESCRIPTION

List::Flat is a module with functions to flatten a deep structure
of array references into a single flat list.

=head1 FUNCTIONS

=over

=item B<flat()>

This function takes its arguments and returns either a list (in
list context) or an array reference (in scalar context) that is
flat, so there are no (non-blessed) array references in the result.

If there are any circular references -- an array reference that has
an entry that points to itself, or an entry that points to another
array reference that refers to the first array reference -- it will
throw an exception.

 my @list = (1, 2, 3);
 push @list, \@list;
 my @flat = flat(@list);
 # throws exception
 
But it will process it again if it's repeated but not circular.

 my @sublist = ( 4, 5, 6 );
 my @repeated = ( \@sublist, \@sublist, \@sublist);
 my @repeated_flat = flat (@repeated);
 # (4, 5, 6, 4, 5, 6, 4, 5, 6)

=item B<flat_r()>

This function takes its arguments and returns either a list (in
list context) or an array reference (in scalar context) that is
flat, so there are no (non-blessed) array references in the result.

If there are any circular references -- an array reference that has
an entry that points to itself, or an entry that points to another
array reference that refers to the first array reference -- it will
not descend infinitely. It skips any reference that it is currently
processing. So:

 my @list = (1, 2, 3);
 push @list, \@list;
 my @flat = flat(@list);
 # (1, 2, 3)
 
But it will process it again if it's repeated but not circular.

 my @sublist = ( 4, 5, 6 );
 my @repeated = ( \@sublist, \@sublist, \@sublist);
 my @repeated_flat = flat (@repeated);
 # (4, 5, 6, 4, 5, 6, 4, 5, 6)
 
=item B<flat_f()>

This function takes its arguments and returns either a list (in
list context) or an array reference (in scalar context) that is
flat, so there are no (non-blessed) array references in the result.

It does not check for circular references, and so will go into an 
infinite loop with something like

 @a = ( 1, 2, 3);
 push @a, \@a;
 @b = flat_f(\@a);

So don't do that. Use C<flat()> or C<flat_r()> instead.

When it is fed non-infinite lists, this function seems to be about 
twice as fast as C<flat()>.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The functions will normally use Ref::Util to determine whether an
element is an array reference or not, but if the environment variable
$PERL_LIST_FLAT_NO_REF_UTIL is set to a true value, or the perl
variable List::Flat::NO_REF_UTIL is set to a true value before
importing it, it will use its internal pure-perl implementation.

=head1 DEPENDENCIES

It has one optional dependency, L<Ref::Util|Ref::Util>. 
If it is not present, a pure perl implementation is used instead.

=head1 SEE ALSO

There are several other modules on CPAN that do similar things.

=over

=item Array::DeepUtils

I have not tested this code, but it appears that its collapse()
routine does not handle circular references.  Also, it must be
passed an array reference rather than a list.

=item List::Flatten

List::Flatten flattens lists one level deep only, so

  1, 2, [ 3, [ 4 ] ]

is returned as 

  1, 2, 3, [ 4 ]

This might be, I suppose, useful in some circumstance or other.

=item List::Flatten::Recursive

The code from this module works well and does the same thing as
C<flat_r()>, but it seems to be somewhat slower than List::Flat (in
my testing; better testing welcome) due to its use of recursive
subroutine calls rather than using a queue of items to be processed.
Moreover, it is reliant on Exporter::Simple, which apparently does
not pass tests on perls newer than 5.10.

=item List::Flatten::XS

This is very fast and is worth using if one can accept its limitations.
These are, however, significant:

=over

=item *

It flattens blessed array references as well as unblessed ones,
which means that any array-based objects (for example,
L<Path::Tiny|Path::Tiny> objects) will be flattened as well.
Array-based objects aren't all that common, but that's not usually
what's desired.

=item *

Like all XS modules it requires a C compiler on the host system to be
installed, or some kind of special binary installation (e.g., ActiveState's 
ppm).

=item *

It goes into an infinite loop with circular references. 

=item *

It must be passed an array refeernce rather than a list.

=back

It does have the potentially useful feature of being able to specify
the level to which the array is flattened (so one can ask for the
first and second levels to be flat, but the third level preserved
as references).

At one point in the development of List::Flat there was an intent to use this
module to speed up performance, but it wasn't acceptable that it flattened
objects.

=back

It is certainly possible that there are others.

=head1 ACKNOWLEDGEMENTS

Ryan C. Thompson's L<List::Flatten::Recursive|List::Flatten::Recursive> 
inspired the creation of the C<flat_r()> function.

Aristotle Pagaltzis suggested throwing an exception upon seeing
a circular reference rather than simply skipping it.

Mark Jason Dominus's book L<Higher-Order Perl|http://hop.perl.plover.com> 
was and continues to be extremely helpful and informative.  

L<Toby Inkster|http://toby.ink> contributed a patch to slightly 
speed up C<flat()> and C<flat_r()>.

=head1 BUGS AND LIMITATIONS

If you bless something into a class called 'ARRAY', the pure-perl version 
will break. But why would you do that?

=head1 AUTHOR

Aaron Priven <apriven@actransit.org>

=head1 COPYRIGHT & LICENSE

Copyright 2017

This program is free software; you can redistribute it and/or modify it
under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

This program is distributed in the hope that it will be useful, but
WITHOUT  ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or  FITNESS FOR A PARTICULAR PURPOSE. 
