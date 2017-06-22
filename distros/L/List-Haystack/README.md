# NAME

List::Haystack - A immutable list utility to find element

# SYNOPSIS

### Basic (not lazy mode)

    use List::Haystack;

    my $haystack = List::Haystack->new([qw/foo bar foo/]); # <= create internal structure here

    $haystack->find('foo'); # <= 1 (true value)
    $haystack->find('bar'); # <= 1 (true value)
    $haystack->find('xxx'); # <= 0 (false value)

    $haystack->cnt('foo'); # <= 2 (number of occurrences)
    $haystack->cnt('bar'); # <= 1 (number of occurrences)
    $haystack->cnt('xxx'); # <= 0 (number of occurrences)

### Lazy

    use List::Haystack;

    my $haystack = List::Haystack->new([qw/foo bar foo/], {lazy => 1});

    $haystack->find('foo'); # <= 1 (true value, create internal structure here)
    $haystack->find('bar'); # <= 1 (true value)
    $haystack->find('xxx'); # <= 0 (false value)

    $haystack->cnt('foo'); # <= 2 (number of occurrences)
    $haystack->cnt('bar'); # <= 1 (number of occurrences)
    $haystack->cnt('xxx'); # <= 0 (number of occurrences)

# DESCRIPTION

List::Haystack is a utility to find element for list. This module works **immutably**.

This module converts the given list to internal structure to find the element fast. This conversion runs only at once.
That is to say, if you want to modify the target of list, you must create new instance of this module.

# METHODS

## `new($list: ArrayRef|undef, $option: HashRef): List::Haystack`

A constructor.  `$list` is a target of list to find. It must be ArrayRef or undef; if undef is given, `find` and `cnt` always return 0.

`$option` is an HashRef argument of option. If you specify `lazy`, it puts off creation the internal structure until instance method is called (i.e. constructor doesn't create internal structure).

e.g.
    List::Haystack->new(\[...\], {lazy => 1}

## `haystack(): HashRef`

A getter method. This method returns a HashRef that contains element as key and number of occurrences as value.

## `find($element: Any): Bool`

This method returns whether given list contains `$element` or not.

## `cnt($element: Any): Int`

This method returns number of occurrences of given `$element`.

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
