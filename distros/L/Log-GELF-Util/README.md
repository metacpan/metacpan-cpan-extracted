[![Build Status](https://travis-ci.org/strategicdata/log-gelf-util.svg?branch=master)](https://travis-ci.org/strategicdata/log-gelf-util)
# NAME

Log::GELF::Util - Utility functions for Graylog's GELF format.

# SYNOPSIS

    use Log::GELF::Util qw( encode );

    my $msg = encode( { short_message => 'message', } );


    use Log::GELF::Util qw( :all );

    sub process_chunks {

        my @accumulator;
        my $msg;

        do {
            $msg = dechunk(
                \@accumulator,
                decode_chunk(shift())
            );
        } until ($msg);

        return uncompress($msg);
    };

    my $hr = validate_message( short_message => 'message' );

# DESCRIPTION

Log::GELF::Util is a collection of functions and data structures useful
when working with Graylog's GELF Format version 1.1. It strives to support
all of the features and options as described in the [GELF
specification](http://docs.graylog.org/en/latest/pages/gelf.html).

# FUNCTIONS

## validate\_message( short\_message => $ )

Returns a HASHREF representing the validated message with any defaulted
values added to the data structure.

Takes the following message parameters as per the GELF message
specification:

- short\_message

    Mandatory string, a short descriptive message

- version

    String, must be '1.1' which is the default.

- host

    String, defaults to hostname() from [Sys::Hostname](https://metacpan.org/pod/Sys::Hostname).

- timestamp

    Timestamp, defaults to time() from [Time::HiRes](https://metacpan.org/pod/Time::HiRes).

- level

    Integer, equal to the standard syslog levels, default is 1 (ALERT).

- facility

    Deprecated, a warning will be issued.

- line

    Deprecated, a warning will be issued.

- file

    Deprecated, a warning will be issued.

- \_\[additional\_field\]

    Parameters prefixed with an underscore (\_) will be treated as an additional
    field. Allowed characters in field names are any word character (letter,
    number, underscore), dashes and dots. As per the specification '\_id' is
    disallowed.

## encode( \\% )

Accepts a HASHREF representing a GELF message. The message will be
validated with ["validate\_message"](#validate_message).

Returns a JSON encoded string representing the message.

## decode( $ )

Accepts a JSON encoded string representing the message. This will be
converted to a hashref and validated with ["validate\_message"](#validate_message).

Returns a HASHREF representing the validated message with any defaulted
values added to the data structure.

## compress( $ \[, $\] )

Accepts a string and compresses it. The second parameter is optional and
can take the value `zlib` or `gzip`, defaulting to `gzip`.

Returns a compressed string.

## uncompress( $ )

Accepts a string and uncompresses it. The compression method (`gzip` or
`zlib`) is determined automatically. Uncompressed strings are passed
through unaltered.

Returns an uncompressed string.

## enchunk( $ \[, $, $\] )

Accepts an encoded message (JSON string) and chunks it according to the
GELF chunking protocol.

The optional second parameter is the maximum size of the chunks to produce,
this must be a positive integer or the special strings `lan` or `wan`,
see ["parse\_size"](#parse_size). Defaults to `wan`. A zero chunk size means no chunking
will be applied.

The optional third parameter is the message id used to identify associated
chunks. This must be 8 bytes. It defaults to 8 bytes of randomness generated
by [Math::Random::MT](https://metacpan.org/pod/Math::Random::MT).

If the message size is greater than the maximum size then an array of
chunks is retuned, otherwise the message is retuned unaltered as the first
element of an array.

## dechunk( \\@, \\% )

This facilitates reassembling a GELF message from a stream of chunks.

It accepts an ARRAYREF for accumulating the chunks and a HASHREF
representing a decoded message chunk as produced by ["decode\_chunk"](#decode_chunk).

It returns undef if the accumulator is not complete, i.e. all chunks have
not yet been passed it.

Once the accumulator is complete it returns the de-chunked message in the
form of a string. Note that this message may still be compressed.

Here is an example usage:

    sub process_chunks {

        my @accumulator;
        my $msg;

        do {
            $msg = dechunk(
                \@accumulator,
                decode_chunk(shift())
            );
        } until ($msg);

        return uncompress($msg);
    };

## is\_chunked( $ )

Accepts a string and returns a true value if it is a GELF message chunk.

## decode\_chunk( $ )

Accepts a GELF message chunk and returns an ARRAYREF representing the
unpacked chunk. Dies if the input is not a GELF chunk.

The message consists of the following keys:

    id
    sequence_number
    sequence_count
    data

## parse\_level( $ )

Accepts a `syslog` style level in the form of a number (1-7) or a string
being one of `emerg`, `alert`, `crit`, `err`, `warn`, `notice`,
`info`, or `debug`. Dies upon invalid input.

The string forms may also be elongated and will still be accepted. For
example `err` and `error` are equivalent.

The associated syslog level is returned in numeric form.

## parse\_size( $ )

Accepts an integer specifying the chunk size or the special string values
`lan` or `wan` corresponding to 8154 or 1420 respectively. An explanation
of these values is in the code.

Returns the passed size or the value corresponding to the `lan` or `wan`.

["parse\_size"](#parse_size) dies upon invalid input.

# CONSTANTS

All Log::Gelf::Util constants are Readonly perl structures. You must use
sigils when referencing them. They can be imported individually and are
included when importing ':all';

## $GELF\_MSG\_MAGIC

The magic number used to identify a GELF message chunk.

## $ZLIB\_MAGIC

The magic number used to identify a Zlib deflated message.

## $GZIP\_MAGIC

The magic number used to identify a gzipped message.

## %LEVEL\_NAME\_TO\_NUMBER

A HASH mapping the level names to numbers.

## %LEVEL\_NUMBER\_TO\_NAME

A HASH mapping the level numbers to names.

## %GELF\_MESSAGE\_FIELDS

A HASH where each key is a valid core GELF message field name. Deprecated
fields are associated with a false value.

# LICENSE

Copyright (C) Strategic Data.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# AUTHOR

Adam Clarke &lt;adamc@strategicdata.com.au>
