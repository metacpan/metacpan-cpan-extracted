[![Build Status](https://travis-ci.org/karupanerura/List-Range.svg?branch=master)](https://travis-ci.org/karupanerura/List-Range) [![Coverage Status](http://codecov.io/github/karupanerura/List-Range/coverage.svg?branch=master)](https://codecov.io/github/karupanerura/List-Range?branch=master)
# NAME

List::Range - Range processor for integers

# SYNOPSIS

    use List::Range;

    my $range = List::Range->new(name => "one-to-ten", lower => 1, upper => 10);
    $range->includes(0);   # => false
    $range->includes(1);   # => true
    $range->includes(3);   # => true
    $range->includes(10);  # => true
    $range->includes(11);  # => false

    $range->includes(0..100); # => (1..10)
    $range->includes(sub { $_ + 1 }, 0..100); # => (1..11)

    $range->excludes(0..100); # => (11..100)
    $range->excludes(sub { $_ + 1 }, 0..100); # => (0, 12..100)

# DESCRIPTION

List::Range is range object of integers. This object likes `0..10`.

# METHODS

## List::Range->new(%args)

Create a new List::Range object.

### ARGUMENTS

- name

    Name of the range. Defaults `""`.

- lower

    Lower limit of the range. Defaults `-Inf`.

- upper

    Upper limit of the range. Defaults `+Inf`.

## $range->includes(@values)

Returns the values that is included in the range.

## $range->excludes(@values)

Returns the values that is not included in the range.

## $range->all

Returns all values in the range. (likes `$lower..$upper`)
`@$range` is alias of this.

# SEE ALSO

[Number::Range](https://metacpan.org/pod/Number::Range) [Range::Object](https://metacpan.org/pod/Range::Object) [Parse::Range](https://metacpan.org/pod/Parse::Range)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura &lt;karupa@cpan.org>
