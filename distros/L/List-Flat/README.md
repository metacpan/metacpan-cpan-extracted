# NAME

List::Flat - Functions to flatten a structure of array references

# VERSION

This documentation refers to version 0.003

# SYNOPSIS

    use List::Flat(qw/flat flat_f flat_r/);
    
    my @list = ( 1, [ 2, 3, [ 4 ], 5 ] , 6 );
    
    my @newlist = flat_f(@list);
    # ( 1, 2, 3, 4, 5, 6 )

    push @list, [ 7, \@list, 8, 9 ];
    my @newerlist = flat_r(@list);
    # ( 1, 2, 3, 4, 5, 6, 7, 8, 9 )
    
    my @evennewerlist = flat(@list);
    # throws exception
    

# DESCRIPTION

List::Flat is a module with functions to flatten a deep structure
of array references into a single flat list.

# FUNCTIONS

- **flat()**

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

- **flat\_r()**

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
        

- **flat\_f()**

    This function takes its arguments and returns either a list (in
    list context) or an array reference (in scalar context) that is
    flat, so there are no (non-blessed) array references in the result.

    It does not check for circular references, and so will go into an 
    infinite loop with something like

        @a = ( 1, 2, 3);
        push @a, \@a;
        @b = flat_f(\@a);

    So don't do that. Use `flat()` or `flat_r()` instead.

    When it is fed non-infinite lists, this function seems to be about 
    twice as fast as `flat()`.

# CONFIGURATION AND ENVIRONMENT

The functions will normally use Ref::Util to determine whether an
element is an array reference or not, but if the environment variable
$PERL\_LIST\_FLAT\_NO\_REF\_UTIL is set to a true value, or the perl
variable List::Flat::NO\_REF\_UTIL is set to a true value before
importing it, it will use its internal pure-perl implementation.

# DEPENDENCIES

It has one optional dependency, [Ref::Util](https://metacpan.org/pod/Ref::Util). 
If it is not present, a pure perl implementation is used instead.

# SEE ALSO

There are several other modules on CPAN that do similar things.

- Array::DeepUtils

    I have not tested this code, but it appears that its collapse()
    routine does not handle circular references.  Also, it must be
    passed an array reference rather than a list.

- List::Flatten

    List::Flatten flattens lists one level deep only, so

        1, 2, [ 3, [ 4 ] ]

    is returned as 

        1, 2, 3, [ 4 ]

    This might be, I suppose, useful in some circumstance or other.

- List::Flatten::Recursive

    The code from this module works well and does the same thing as
    `flat_r()`, but it seems to be somewhat slower than List::Flat (in
    my testing; better testing welcome) due to its use of recursive
    subroutine calls rather than using a queue of items to be processed.
    Moreover, it is reliant on Exporter::Simple, which apparently does
    not pass tests on perls newer than 5.10.

- List::Flatten::XS

    This is very fast and is worth using if one can accept its limitations.
    These are, however, significant:

    - It flattens blessed array references as well as unblessed ones,
    which means that any array-based objects (for example,
    [Path::Tiny](https://metacpan.org/pod/Path::Tiny) objects) will be flattened as well.
    Array-based objects aren't all that common, but that's not usually
    what's desired.
    - Like all XS modules it requires a C compiler on the host system to be
    installed, or some kind of special binary installation (e.g., ActiveState's 
    ppm).
    - It goes into an infinite loop with circular references. 
    - It must be passed an array refeernce rather than a list.

    It does have the potentially useful feature of being able to specify
    the level to which the array is flattened (so one can ask for the
    first and second levels to be flat, but the third level preserved
    as references).

    At one point in the development of List::Flat there was an intent to use this
    module to speed up performance, but it wasn't acceptable that it flattened
    objects.

It is certainly possible that there are others.

# ACKNOWLEDGEMENTS

Ryan C. Thompson's [List::Flatten::Recursive](https://metacpan.org/pod/List::Flatten::Recursive) 
inspired the creation of the `flat_r()` function.

Aristotle Pagaltzis suggested throwing an exception upon seeing
a circular reference rather than simply skipping it.

Mark Jason Dominus's book [Higher-Order Perl](http://hop.perl.plover.com) 
was and continues to be extremely helpful and informative.  

[Toby Inkster](http://toby.ink) contributed a patch to slightly 
speed up `flat()` and `flat_r()`.

# BUGS AND LIMITATIONS

If you bless something into a class called 'ARRAY', the pure-perl version 
will break. But why would you do that?

# AUTHOR

Aaron Priven <apriven@actransit.org>

# COPYRIGHT & LICENSE

Copyright 2017

This program is free software; you can redistribute it and/or modify it
under the terms of either:

- the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or
- the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but
WITHOUT  ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or  FITNESS FOR A PARTICULAR PURPOSE. 
