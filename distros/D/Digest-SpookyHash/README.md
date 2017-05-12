# NAME

Digest::SpookyHash - SpookyHash implementation for Perl

# SYNOPSIS

    use strict;
    use warnings;
    use Digest::SpookyHash qw(spooky32 spooky64 spooky128);
    
    my $key = 'spooky';
    
    my $hash32  = spooky32($key, 0);
    my $hash64  = spooky64($key, 0);
    my ($hash64_1, $hash64_2) = spooky128($key, 0);

# DESCRIPTION

This module provides an interface to SpookyHash(SpookyHash V2) functions.

**This module works only in the environment which supported a 64-bit integer**.

**This module works only in little endian machine**.

# FUNCTIONS

## spooky32($key \[, $seed = 0\])

Calculates a 32 bit hash.

## spooky64($key \[, $seed = 0\])

Calculates a 64 bit hash.

## ($v1, $v2) = spooky128($key \[, $seed1 = 0, $seed2 =0\])

Calculates a 128 bit hash. The result is returned as a two element list of 64 bit integers.

# SEE ALSO

[http://burtleburtle.net/bob/hash/spooky.html](http://burtleburtle.net/bob/hash/spooky.html)

# AUTHOR

Hideaki Ohno <hide.o.j55 {at} gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
