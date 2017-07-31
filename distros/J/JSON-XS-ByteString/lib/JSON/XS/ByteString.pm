package JSON::XS::ByteString;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(encode_json encode_json_unblessed decode_json decode_json_safe);
our $VERSION = 1.003001;

require XSLoader;
XSLoader::load('JSON::XS::ByteString', $VERSION);

=head1 NAME

JSON::XS::ByteString - A more predictable and convenient XS implementation for JSON

=head1 SYNOPSIS

    use JSON::XS::ByteString qw(encode_json encode_json_unblessed decode_json decode_json_safe);

    $json_string = encode_json($perl_data);
    $perl_data = decode_json($json_string);

    $json_string = encode_json_unblessed($perl_data);
        # the same behavior as encode_json
        #  but encode blessed references as reference strings,
        #  like 'Object=HASH(0xffffffff)'

=head1 DESCRIPTION

This module is a XS implementation for JSON. It provide a more predictable behavior than L<JSON::XS> by always producing strings in JSON for normal scalars.
And you can force it to produce numbers in JSON by putting references to numbers.

All the string data are treated as UTF-8 octets and just copy them in and out directly, except C<">, C<\> and characters that C<< ord($char) < 32 >>

C<decode_json> will return an undef without exceptions with invalid json string.

=head1 DESIGN CONSIDERATION

=head2 I didn't transfer the numeric value from C<json_decode> back to string values

Because in the pure Perl world, there's insignificant difference between numeric or string.
So I think we don't need to do it since the result will be used in Perl.

=head2 I didn't transfer the numeric value from C<json_decode> back to reference values

Let C<json_decode> preserve the identical structure as it received.

=head1 FUNCTIONS

=head2 $json_string = encode_json($perl_data)

Get a JSON string from a perl data structure. Treat blessed objects as normal references.

=head2 $json_string = encode_json_unblessed($perl_data)

Get a JSON string from a perl data structure. Treat blessed objects as strings (such as 'Object=HASH(0xffffffff)')

=head2 $perl_data = decode_json($json_string)

Get the perl data structure back from a JSON string.

If the given string is not a valid JSON string, it will return an undef without exceptions but warns an offset where it encountered the unrecognized character.

=head2 $perl_data = decode_json_safe($json_string)

The same as C<decode_json> except that C<decode_json_safe> will not warn.

=head1 SEE ALSO

L<JSON::XS>

This mod's github repository L<https://github.com/CindyLinz/Perl-JSON-XS-ByteString>

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2017 by Cindy Wang (CindyLinz)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
