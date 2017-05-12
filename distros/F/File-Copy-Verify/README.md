[![Build Status](https://travis-ci.org/JaSei/File-Copy-Verify.svg?branch=master)](https://travis-ci.org/JaSei/File-Copy-Verify)
# NAME

File::Copy::Verify - data-safe copy

# SYNOPSIS

    use File::Copy::Verify qw(verify_copy);
    use Try::Tiny::Retry;

    retry {
        verify_copy('a', 'b'); #or copy or cp - all variants are exportable
    };

    #OOP equivalent:

    $verify_copy = File::Copy::Verify->new(
        src => 'a',
        dst => 'b',
    );
    retry {
        $verify_copy->copy();
    };


    #I know source SHA-256 hash and I can use for validation
    
    retry {
        File::Copy::Verify::copy('a', 'b', {src_hash => '0'x64, hash_algo => 'SHA-256'});
    };

    #OOP equivalent
    
    $verify_copy = File::Copy::Verify->new(
        src       => 'a',
        src_hash  => '0' x 64,
        dst       => 'b',
        hash_algo => 'SHA-256',
    );
    retry {
        $verify_copy->copy();
    };

# DESCRIPTION

This module calculates hash before and after copying and if the hash doesn't match, then dies. I recommend Try::Tiny::Retry module for copy retry mechanism.
This module is useful for network storages/filesystems, but it is harmful for local storages/filesystems because of overhead. The \`verified\_copy\` function is at least 3 times slower then standard \`copy\`!

File::Copy::Verify is module for verifying copy. Some storages (in particular net storages) can have troubles with valid copy and `copy` function from [File::Copy](https://metacpan.org/pod/File::Copy) doesn't find this problems (like random buffers in copied file).

This module calculates hash before and after copying and if hash doesn't match, then dies. I recommend [Try::Tiny::Retry](https://metacpan.org/pod/Try::Tiny::Retry) module for copy retry mechanism.

This module is useful for network storages/filesystems, but it is harmful for localstorages/filesystems because of overhead. The `verify_copy`function is at least 3 times slower then standard `copy`!

# METHODS

## new(%attributes)

### %attributes

#### src

source path

#### dst

destination path

#### hash\_algo

digest alghoritm used for check

default is fast _MD5_

more about [Digest](https://metacpan.org/pod/Digest)

#### src\_hash

manualy set source hash

this is usefully if I know source hash (doesn't calculate again)

#### dst\_hash

manualy set destination hash

this is usefully if I know destination hash (doesn't calculate again)

#### keep\_invalid

If is file invalid (means hash-check failed), `dst` is removed.

This decreases potentional problems with bad-copied files.

If you need keep this bad file anyway. Or for debugging. Use this option.

## copy()

## move()

# FUNCTIONS

## verify\_copy($src, $dst, $options)

`$options` - same parameters (except `src` and `dst`) like in constructor [new](#new-attributes)

## copy

alias for [verify\_copy](#verify_copy-src-dst-options)

## cp

alias for [verify\_copy](#verify_copy-src-dst-options)

## verify\_move($src, $dst, $options)

same as [verify\_copy](#verify_copy-src-dst-options) and after success copy remove source `$src` file

## move

alias for [verify\_move](#verify_move-src-dst-options)

## mv

alias for [verify\_move](#verify_move-src-dst-options)

# SEE ALSO

[File::Copy::Vigilant](https://metacpan.org/pod/File::Copy::Vigilant) - Looks really good, don't support other digests - only MD5, don't support hard-set src or dst hash. Support retry mechanism by default.

[File::Copy::Reliable](https://metacpan.org/pod/File::Copy::Reliable) - only "checks that the file size of the copied or moved file is the same as the source".

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Seidl <seidl@avast.com>
