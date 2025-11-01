# NAME

Digest::prvhash64 - Variable length hashing

# SYNOPSIS

    use Digest::prvhash64;

    my $raw  = prvhash64($str, $hash_bytes);     # Raw bytes
    my $hex  = prvhash64_hex($str, $hash_bytes); # Hex string

    # 64bit "minimal" variant
    my $num  = prvhash64_64m($str);     # 64bit unsigned integer
    my $hex2 = prvhash64_64m_hex($str); # 64bit hex string

# DESCRIPTION

Digest::prvhash64 is a _variable length_ hashing algorithm. It is NOT suitable for
cryptographic purposes (password storage, signatures, etc.).

# METHODS

All functions accept data as a byte string. For deterministic results, callers
should ensure text is encoded to bytes.

## **prvhash64($str, $hash\_size, $seed = 0)**

Compute the hash of `$str` and return the digest as raw bytes.
The digest may contain NULs and other non-printable bytes.

## **prvhash64\_hex($str, $hash\_size, $seed = 0)**

Like `prvhash64`, but returns the digest encoded as a lowercase hexadecimal
string.

## **prvhash64\_64m($str, $seed = 0)**

Compute the "minimal" 64bit hash of `$str` and return a 64bit unsigned integer.

## **prvhash64\_64m\_hex($str, $seed = 0)**

Compute the "minimal" 64bit hash of `$str` and return a lowercase hexadecimal
string.

# ENCODING AND PORTABILITY

This hash operates on bytes. If you pass Perl characters (wide/unicode strings)
the result may vary across platforms and Perl builds. For reproducible results,
encode strings to a byte representation explicitly, for example:

    use Encode qw(encode);
    my $hex = prvhash64_hex( encode('UTF-8', $text) );

# SEE ALSO

Digest(3), Encode, Digest::MD5, Digest::SHA

# AUTHOR

Scott Baker - https://www.perturb.org/
