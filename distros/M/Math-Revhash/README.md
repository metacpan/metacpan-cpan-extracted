# NAME

Math::Revhash - Reverse hash computation library

# SYNOPSIS

```perl
use Math::Revhash qw( revhash revunhash );

# OO style
my $revhash = Math::Revhash->new( $length, $A, $B, $C );
my $hash = $revhash->hash( $number );
my $number = $revhash->unhash( $hash );

# Procedural style
my $hash = revhash( $number, $length, $A, $B, $C );
my $hash = revhash( $number, 5 );
my $number = revunhash( $hash, $length, $A, $B, $C );

# See UNSAFE MODE
$Math::Revhash::UNSAFE = 1;
```

# DESCRIPTION

This module is intended for fast and lightweight numbers reversible hashing.
Say there are millions of entries inside RDBMS and each entry identified with
sequential primary key.
Sometimes we want to expose this key to users, i.e. in case it is a session ID.
Due to several reasons it could be a good idea to hide from the outer world
that those session IDs are just a generic sequence of integers.
This module will perform fast, lightweight and reversible translation between
simple sequence `1, 2, 3, ...` and something like `3287, 8542, 1337, ...`
without need for hash-table lookups, large memory storage and any other
expensive mechanisms.

So far, this module is only capable of translating positive non-zero integers.
To use the module you can either choose one of hash lengths: 1..9,
for which all other parameters are pre-defined, or specify any positive
`$length` with non-default `$A` parameter (see below).
In any case `$number` for hashing should not exceed predefined hash length.
`$B` and `$C` parameters could also be specified to avoid extra modular
inverse and power calculation, respectively.

# SUBROUTINES

## revhash

Compute `$hash = revhash($number, $length, $A, $B, $C)`

- `$number` is the source number to be hashed.
- `$length` is required hash length in digits.
- `$A` _(optional for pre-defined lengths)_ is the first parameter of
hash function.

    There are some hard-coded `$A` values for pre-defined lengths.
    You are free to specify any positive `$A` to customize the function.
    It is recommended to choose only primary numbers for `$A` to avoid possible
    collisions.
    `$A` should not be too short or too huge digit number.
    It is recommended to start with any primary number close to
    `10 ** ($length + 1)`.
    You are encouraged to play around it on your own.

- `$B` _(optional)_ is the second parameter of hash function.

    It is a modular inverse of `$A` and is
    being computed as `$B = Math::BigInt->bmodinv($A, 10 ** $length)` unless
    explicitly specified.

- `$C` _(optional)_ is the third parameter of hash function.

    As our numbers are decimal it is just `10` to the power of `$length`:
    `$C = 10 ** $length`.

## revunhash

Compute `$number = revunhash($hash, $length, $A, $B, $C)`.
It takes the same arguments as `revhash` besides:

- `$hash` is hash value that should be translated back to a number.

## hash

Just an object oriented alias for revhash: `$hash = $obj->hash($number)`.
All the hash function parameters will be taken from the object itself.

## unhash

Just an object oriented alias for revunhash:
`$number = $obj->unhash($hash)`.
All the hash function parameters will be taken from the object itself.

## new

`$obj = Math::Revhash->new($length, $A, $B, $C)` is an object constructor
that will firstly check and vivify all the arguments and store them inside
new object.

# UNSAFE MODE

Arguments parsing and parameters auto-computing takes some time thus sometimes
it would be preffered to avoid this phase on every translation operation.
There is an UNSAFE mode to speed up the whole process (see SYNOPSIS).
In this mode all arguments become mandatory on `revhash/revunhash` calls.
You can either use OO style and still imply and check arguments on object
creation, or use procedural style and specify each argument on every call.
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

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Sergei Zhmylev.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
