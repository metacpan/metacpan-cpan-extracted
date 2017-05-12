[![Build Status](https://travis-ci.org/JaSei/File-Copy-Recursive-Verify.svg?branch=master)](https://travis-ci.org/JaSei/File-Copy-Recursive-Verify)
# NAME

File::Copy::Recursive::Verify - data-safe recursive copy

# SYNOPSIS

    use File::Copy::Recursive::Verify qw(verify_rcopy);

    verify_rcopy($dir_a, $dir_b);

    #OOP equivalent

    File::Copy::Recursive::Verify->new(
        src_dir => $dir_a,
        dst_dir => $dir_b,
    )->copy();

    #some complex copy - I know SHA-256 hash of subdir/a.dat file
    #tree $dir_a:
    #.
    #├── c.dat
    #└── subdir
    #    ├── a.dat
    #    └── b.dat

    verify_rcopy($dir_a, $dir_b, {tries => 3, hash_algo => 'SHA-256', src_hash => {'subdir/a.dat' => '0'x64}});

    #OOP equivalent

    File::Copy::Recursive::Verify->new(
        src_dir => $dir_a,
        dst_dir => $dir_b,
        tries   => 3,
        hash_algo => 'SHA-256',
        src_hash => {'subdir/a.dat' => 0x64},
    )->copy();

# DESCRIPTION

Use [File::Copy::Verify](https://metacpan.org/pod/File::Copy::Verify) for recursive copy.

# FUNCTIONS

## verify\_rcopy($src\_dir, $dst\_dir, $options)

functional api

Recusive copy of `dir_a` to `dir_b`.

Retry mechanism is via [Try::Tiny::Retry](https://metacpan.org/pod/Try::Tiny::Retry) (Each file will try verify\_copy 10 times with exponential backoff in default).

As verification digest are use fastest _MD5_ in default.

`$options` is HashRef of [attributes](#attributes).

return _HashRef_ of copied files (key source, value destination)

## rcopy

alias of `verify_rcopy`

# METHODS

## new(%attributes)

### %attributes

#### src\_dir

source dir

#### src\_hash

source _HashRef_ of path -> hash

#### dst\_dir

destination dir

#### dst\_hash

destination _HashRef_ of path -> hash

#### hash\_algo

hash algorithm

default _MD5_

#### tries

number of tries

more about retry - [Try::Tiny::Retry](https://metacpan.org/pod/Try::Tiny::Retry)

## copy;

start recursive copy 

return _HashRef_ of copied files (key source, value destination)

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Seidl <seidl@avast.com>
