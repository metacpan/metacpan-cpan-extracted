# NAME

Math::Revhash - Reversible hashes library

# SYNOPSIS

```perl
    use Math::Revhash qw( revhash revunhash );

    # OO style
    my $revhash = Math::Revhash->new( $length, $A, $B );
    my $hash = $revhash->hash( $number );
    my $number = $revhash->unhash( $hash );

    # Procedural style
    my $hash = revhash( $number, $length, $A, $B );
    my $number = revunhash( $hash, $length, $A, $B );

    # See UNSAFE MODE
    $Math::Revhash::UNSAFE = 1;
```

# DESCRIPTION

This module is intended for fast and lightweight numbers reversible hashing.
Say there are millions of entries inside RDBMS and each entry identified with
sequential primary key.
Sometimes we want to expose this key to users, i.e. in case it is a session ID.
Due to multiple reasons it could be a good idea to hide from the outer world
that those session IDs are just a generic sequence of integers.
This module will perform fast, lightweight and reversible translation between
simple sequence `1, 2, 3, ...` and something like `3287, 8542, 1337, ...`
without need for hash-table lookups, large memory storage and any other
expensive things.

So far, this module is only capable of translating positive non-zero integers.
To use the module you can either choose one of existing hash lengths: 1..9, or
specify any positive `$length` with non-default `$A` parameter.
In any case `data` for hashing should not exceed predefined hash length.
`$B` parameter could also be specified to avoid extra modular inverse
calculation.

# SUBROUTINES/METHODS

## revhash($number, $length, $A, $B)

- `$number` --

    the number to be hashed.

- `$length` --

    required hash length.

- `$A` --

    _(optional for pre-defined lengths)_ a parameter of hash function.
    There are some hard-coded `$A` values for pre-defined lengths.
    You are free to specify any positive `$A` to customize the function.
    It is recommended to choose only primary numbers for `$A` to avoid possible
    collisions.
    `$A` should not be too short or too huge digit number.
    It's recommended to start with any primary number close to `10 ** ($len + 1)`.
    You are encouraged to play around it on your own.

- `$B` --

    _(optional)_ modular inverse of `$A`:

        $B = Math::BigInt->bmodinv($A, 10 ** $len)

## revunhash($hash, $length, $A, $B)

- `$hash` --

    hash value that should be translated back to a number.

## hash($number)

alias for revhash.

## unhash($hash)

alias for revunhash.

## new($length, $A, $B)

object constructor that stores `$length`, `$A`, and `$B` in the object.

# UNSAFE MODE

Arguments parsing and parameters auto-computing takes some time.
There is an UNSAFE mode to speed up the whole process (see SYNOPSIS).
In this mode all arguments becomes mandatory.
Use this mode with extra caution.

# AUTHOR

Sergei Zhmylev, `<zhmylove@cpan.org>`

# BUGS

Please report any bugs or feature requests to official GitHub page at
[https://github.com/zhmylove/math-revhash](https://github.com/zhmylove/math-revhash).
You also can use official CPAN bugtracker by reporting to
`bug-math-revhash at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Revhash](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Revhash).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# INSTALLATION

To install this module, run the following commands:

```sh
    $ perl Makefile.PL
    $ make
    $ make test
    $ make install
```

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Sergei Zhmylev.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
