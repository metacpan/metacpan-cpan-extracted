# NAME

MIME::Base32::XS - Encoding and decoding Base32

# SYNOPSIS

    use MIME::Base32::XS;
     
    $encoded = encode_base32('Foo');
    $decoded = decode_base32($encoded);
    
# DESCRIPTION

This module provides functions to encode and decode strings into and from the Base32 encoding specified in RFC 3548.

# METHODS

## encode_base32

    my $encoded = encode_base32('Baz');

## decode_base32

    my $decoded = decode_base32('IJQXU===');

# AUTHOR

Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`

# CONTRIBUTORS

Orestes Leal Rodriguez `olealrd1981@gmail.com`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
