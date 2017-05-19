# NAME

MIME::Base32 - Base32 encoder and decoder

# SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use MIME::Base32;

    my $encoded = encode_base32('Aladdin: open sesame');
    my $decoded = decode_base32($encoded);

# DESCRIPTION

This module is for encoding/decoding data much the way that [MIME::Base64](https://metacpan.org/pod/MIME::Base64) does.

Prior to version 1.0, [MIME::Base32](https://metacpan.org/pod/MIME::Base32) used the `base32hex` (or `[0-9A-V]`) encoding and
decoding methods by default. If you need to maintain that behavior, please call
`encode_base32hex` or `decode_base32hex` functions directly.

Now, in accordance with [RFC-3548, Section 5](https://tools.ietf.org/html/rfc3548#section-5),
[MIME::Base32](https://metacpan.org/pod/MIME::Base32) uses the `encode_base32` and `decode_base32` functions by default.

# FUNCTIONS

The following primary functions are provided:

## decode

Synonym for `decode_base32`

## decode\_rfc3548

Synonym for `decode_base32`

## decode\_base32

    my $string = decode_base32($encoded_data);

Decode some encoded data back into a string of text or binary data.

## decode\_09AV

Synonym for `decode_base32hex`

## decode\_base32hex

    my $string_or_binary_data = MIME::Base32::decode_base32hex($encoded_data);

Decode some encoded data back into a string of text or binary data.

## encode

Synonym for `encode_base32`

## encode\_rfc3548

Synonym for `encode_base32`

## encode\_base32

    my $encoded = encode_base32("some string");

Encode a string of text or binary data.

## encode\_09AV

Synonym for `encode_base32hex`

## encode\_base32hex

    my $encoded = MIME::Base32::encode_base32hex("some string");

Encode a string of text or binary data. This uses the `hex` (or `[0-9A-V]`) method.

# AUTHORS

Jens Rehsack - &lt;rehsack@cpan.org> - Current maintainer

Chase Whitener

Daniel Peder - sponsored by Infoset s.r.o., Czech Republic
 - <Daniel.Peder@InfoSet.COM> http://www.infoset.com - Original author

# BUGS

Before reporting any new issue, bug or alike, please check
[https://rt.cpan.org/Dist/Display.html?Queue=MIME-Base32](https://rt.cpan.org/Dist/Display.html?Queue=MIME-Base32),
[https://github.com/perl5-utils/MIME-Base32/issues](https://github.com/perl5-utils/MIME-Base32/issues) or
[https://github.com/perl5-utils/MIME-Base32/pulls](https://github.com/perl5-utils/MIME-Base32/pulls), respectively, whether
the issue is already reported.

Please report any bugs or feature requests to
`bug-mime-base32 at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MIME-Base32](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MIME-Base32).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

Any and all criticism, bug reports, enhancements, fixes, etc. are appreciated.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MIME::Base32

You can also look for information at:

- RT: CPAN's request tracker

    [https://rt.cpan.org/Dist/Display.html?Name=MIME-Base32](https://rt.cpan.org/Dist/Display.html?Name=MIME-Base32)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/MIME-Base32](http://annocpan.org/dist/MIME-Base32)

- MetaCPAN

    [https://metacpan.org/release/MIME-Base32](https://metacpan.org/release/MIME-Base32)

# COPYRIGHT AND LICENSE INFORMATION

Copyright (c) 2003-2010 Daniel Peder.  All rights reserved.
Copyright (c) 2015-2016 Chase Whitener.  All rights reserved.
Copyright (c) 2016 Jens Rehsack.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

# SEE ALSO

[MIME::Base64](https://metacpan.org/pod/MIME::Base64), [RFC-3548](https://tools.ietf.org/html/rfc3548#section-5)
