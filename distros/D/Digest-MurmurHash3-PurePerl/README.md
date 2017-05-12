# NAME

Digest::MurmurHash3::PurePerl - Pure perl implementation of MurmurHash3

# SYNOPSIS

    use strict;
    use warnings;
    use Digest::MurmurHash3::PurePerl;

    # Calculate hash value without seed
    my $hash = murmur32($data);
    my @hashes = murmur128($data);
    
    # Calculate hash value with seed
    $hash = murmur32($data, $seed);
    @hashes = murmur128($data, $seed);
    

# DESCRIPTION

Digest::MurmurHash3::PurePerl is pure perl implementation of MurmurHash3.

# METHODS

## $h = murmur32($data \[, $seed\])

Calculates 32-bit hash value.

## ($v1,$v2,$v3,v4) = murmur128($data \[, $seed\])

Calculates 128-bit hash value.

It returns four element list of 32-bit integers.

# SEE ALSO

[Digest::MurmurHash3](https://metacpan.org/pod/Digest::MurmurHash3)

# AUTHOR

Hideaki Ohno  <hide.o.j55 {at} gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
