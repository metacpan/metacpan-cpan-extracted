[![Build Status](https://travis-ci.org/spiritloose/Digest-FarmHash.svg?branch=master)](https://travis-ci.org/spiritloose/Digest-FarmHash)
# NAME

Digest::FarmHash - FarmHash Implementation For Perl

# SYNOPSIS

    use Digest::FarmHash qw(
        farmhash32 farmhash64 farmhash128
        farmhash_fingerprint32 farmhash_fingerprint64 farmhash_fingerprint128
    );

    my $hash = farmhash32($data_to_hash);
    my $hash = farmhash64($data_to_hash);
    my ($lo, $hi) = farmhash128($data_to_hash);

    my $fingerprint = farmhash_fingerprint32($data_to_hash);
    my $fingerprint = farmhash_fingerprint64($data_to_hash);
    my ($lo, $hi) = farmhash_fingerprint128($data_to_hash);

# DESCRIPTION

This module provides an interface to FarmHash functions.

[https://github.com/google/farmhash](https://github.com/google/farmhash)

Note that this module works only in the environment which supported a 64-bit integer.

# FUNCTIONS

- $h = farmhash32($data \[, $seed\])
- $h = farmhash64($data \[, $seed1, $seed2\])
- ($lo, $hi) = farmhash128($data \[, $seed\_lo, $seed\_hi\])
- $f = farmhash\_fingerprint32($data)
- $f = farmhash\_fingerprint64($data)
- ($lo, $hi) = farmhash\_fingerprint128($data)

# SEE ALSO

[https://github.com/google/farmhash](https://github.com/google/farmhash)

# AUTHOR

Jiro Nishiguchi <jiro@cpan.org>

FarmHash by Google, Inc.
