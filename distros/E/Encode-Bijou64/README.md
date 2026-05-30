## Name

Encode::Bijou64 - Encode and decode Bijou64 integers

## Synopsis

```perl
use Encode::Bijou64;

my $bytes = encode_bijou64(123456);
my $num   = decode_bijou64($bytes);
```

## Description

Encode::Bijou64 implements the Bijou64 variable-length
integer encoding format described by Ink & Switch.

Small integers occupy fewer bytes while preserving
efficient decoding.

## Functions

### Encode\_bijou64($Integer)

Encodes a non-negative integer into a Bijou64 byte string.

### Decode\_bijou64($Bytes)

Decodes a Bijou64 byte string and returns the integer value.

## See Also

https://www.inkandswitch.com/tangents/bijou64/

## Author

Scott Baker

## License

Same terms as Perl itself.
