# NAME

List::Utils::MoveElement - Move elements of a list, optionally with XS.

# SYNOPSIS

    use List::Utils::MoveElement;

    my @fruit = qw/apple banana cherry date eggplant/;

    my @array = move_element_to_beginning(2, @fruit);
    # returns (cherry apple banana date eggplant)

    @array = move_element_to_end(0, @fruit);
    # returns (banana cherry date eggplant apple)

    @array = move_element_left(-1, @array);
    # returns (apple banana cherry eggplant date)

    @array = move_element_right(0, @array);
    # returns (banana apple cherry date eggplant)

# INSTALL

The XS module is built by default. To enable the pure Perl version only, pass
`--pureperl-only` to Build.PL or, if installing via cpanm, `--pp` (or
`--pureperl`).

# DESCRIPTION

List::Utils::Move provides four functions for moving an element of an array
to the beginning or end of the array, or left or right by one place. All
functions return the new array without modifying the original.

## move\_element\_left

    @array = move_element_left(N, @array)

Moves element at index `N` of `@array` left by one place by swapping
element `N` with element `N-1`.

If `N` is already the first element, it does nothing.

## move\_element\_right

    @array = move_element_right(N, @array)

Moves element at index `N` of `@array` right by one place by swapping
element `N` with element `N+1`.

If `N` is already the last element, it does nothing.

## move\_element\_to\_beginning

    @array = move_element_to_beginning(N, @array)

Moves element at index `N` of `@array` to the beginning of the array, shifting
elements to the right as necessary. In other words, element `N` becomes
element `0` and elements `0..N-1` become elements `1..N`.

If `N` is already the first element, it does nothing.

## move\_element\_to\_end

    @array = move_element_to_end(N, @array)

Moves element at index `N` of `@array` to the end of the array, shifting
elements to the left as necessary. In other words, element `N` becomes
element `$#array` and elements `N..$#array` become
elements `N+1..$#array`.

If `N` is already the last element, it does nothing.

## EXPORT

By default all four functions are exported. If you would rather not import
anything, you can use the shorter function names (without the "move\_element\_"
prefix) in the following style:

    use List::Utils::MoveElement (); # Do not import
    @array = List::Utils::MoveElement::left(1, @array);

# BUGS and CAVEATS

There is a difference between the Pure Perl and XS versions of this module when 
one if its functions is called in scalar context.

The Pure Perl functions will return the number of elements in the list, while
the XS version will return the last element. 

Scalar context of these functions does not seem useful, so I do not plan to
address this inconsistency.

# SEE ALSO

[List::Util](https://metacpan.org/pod/List%3A%3AUtil),
[List::MoreUtils](https://metacpan.org/pod/List%3A%3AMoreUtils)

# AUTHOR

Dondi Michael Stroma, <dstroma@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2017, 2021 by Dondi Michael Stroma

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
