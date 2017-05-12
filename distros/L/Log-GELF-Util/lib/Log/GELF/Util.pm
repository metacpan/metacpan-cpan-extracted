package Log::GELF::Util;
use 5.010;
use strict;
use warnings;

require Exporter;
use Readonly;

our (
    $VERSION,
    @ISA,
    @EXPORT_OK, 
    %EXPORT_TAGS,
    $GELF_MSG_MAGIC,
    $ZLIB_MAGIC,
    $GZIP_MAGIC,
    %LEVEL_NAME_TO_NUMBER,
    %LEVEL_NUMBER_TO_NAME,
    %GELF_MESSAGE_FIELDS,
    $LEVEL_NAME_REGEX,
);

$VERSION = "0.96";

use Params::Validate qw(
    validate
    validate_pos
    validate_with
    SCALAR
    ARRAYREF
    HASHREF
);
use Time::HiRes qw(time);
use Sys::Syslog qw(:macros);
use Sys::Hostname;
use JSON::MaybeXS qw(encode_json decode_json);
use IO::Compress::Gzip qw(gzip $GzipError);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use IO::Compress::Deflate qw(deflate $DeflateError);
use IO::Uncompress::Inflate qw(inflate $InflateError);
use Math::Random::MT qw(irand);

Readonly $GELF_MSG_MAGIC => pack('C*', 0x1e, 0x0f);
Readonly $ZLIB_MAGIC     => pack('C*', 0x78, 0x9c);
Readonly $GZIP_MAGIC     => pack('C*', 0x1f, 0x8b);

Readonly %LEVEL_NAME_TO_NUMBER => (
    emerg  => LOG_EMERG,
    alert  => LOG_ALERT,
    crit   => LOG_CRIT,
    err    => LOG_ERR,
    warn   => LOG_WARNING,
    notice => LOG_NOTICE,
    info   => LOG_INFO,
    debug  => LOG_DEBUG,
);

Readonly %LEVEL_NUMBER_TO_NAME => (
    &LOG_EMERG   =>  'emerg',
    &LOG_ALERT   =>  'alert',
    &LOG_CRIT    =>  'crit',
    &LOG_ERR     =>  'err',
    &LOG_WARNING =>  'warn',
    &LOG_NOTICE  =>  'notice',
    &LOG_INFO    =>  'info',
    &LOG_DEBUG   =>  'debug',
);

Readonly %GELF_MESSAGE_FIELDS => (
    version        => 1,
    host           => 1,
    short_message  => 1,
    full_message   => 1,
    timestamp      => 1,
    level          => 1,
    facility       => 0,
    line           => 0,
    file           => 0,
);

my $ln = '^(' .
    (join '|', (keys %LEVEL_NAME_TO_NUMBER)) .
    ')\w*$';
$LEVEL_NAME_REGEX = qr/$ln/i;
undef $ln;

@ISA       = qw(Exporter);
@EXPORT_OK = qw( 
    $GELF_MSG_MAGIC
    $ZLIB_MAGIC
    $GZIP_MAGIC
    %LEVEL_NAME_TO_NUMBER
    %LEVEL_NUMBER_TO_NAME
    %GELF_MESSAGE_FIELDS
    validate_message
    encode
    decode
    compress
    uncompress
    enchunk
    dechunk
    is_chunked
    decode_chunk
    parse_level
    parse_size
);

push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');

sub validate_message {
    my %p = validate_with(
        params      => \@_,
        allow_extra => 1,
        spec        => {
            version       => {
                default => '1.1',
                callbacks => {
                    version_check => sub {
                        my $version = shift;
                        $version =~ /^1\.1$/
                            or die 'version must be 1.1, supplied $version';
                    },
                },
            },
            host          => { type => SCALAR, default => hostname() },
            short_message => { type => SCALAR },
            full_message  => { type => SCALAR, optional => 1 },
            timestamp     => {
                type => SCALAR,
                default   => time(),
                callbacks => {
                    ts_format => sub {
                        my $ts = shift;
                        $ts =~ /^\d+(?:\.\d+)*$/
                            or die 'bad timestamp';
                    },
                },
            },
            level         => { type => SCALAR, default  => 1 },
            facility      => {
                type      => SCALAR,
                optional  => 1,
            },
            line          => {
                type      => SCALAR,
                optional  => 1,
                callbacks => {
                    facility_check => sub {
                        my $line = shift;
                        $line =~ /^\d+$/
                            or die 'line must be a number';
                    },
                },
            },
            file          => {
                type      => SCALAR,
                optional  => 1,
            },
        },
    );

    $p{level} = parse_level($p{level});

    foreach my $key ( keys %p ) {

        if ( ! $key =~ /^[\w\.\-]+$/ ) {
            die "invalid field name '$key'";
        }

        if ( $key eq '_id' ||
             ! ( exists $GELF_MESSAGE_FIELDS{$key} || $key =~ /^_/ )
        ) {
            die "invalid field '$key'";
        }

        if ( exists $GELF_MESSAGE_FIELDS{$key}
             && $GELF_MESSAGE_FIELDS{$key} == 0 ) {
            # field is deprecated
            warn "$key is deprecated, send as additional field instead";
        }
    }

    return \%p;
}

sub encode {
    my @p = validate_pos(
        @_,
        { type => HASHREF },
    );

    return encode_json(validate_message(@p));
}

sub decode {
    my @p = validate_pos(
        @_,
        { type => SCALAR },
    );

    my $msg = shift @p;

    return validate_message(decode_json($msg));
}

sub compress {
    my @p = validate_pos(
        @_,
        { type  => SCALAR },
        {
            type    => SCALAR,
            default => 'gzip',
            callbacks => {
                compress_type => sub {
                    my $level = shift;
                    $level =~ /^(?:zlib|gzip)$/
                        or die 'compression type must be gzip (default) or zlib';
                },
            },
        },
    );

    my ($message, $type) = @p;
    
    my $method = \&gzip;
    my $error  = \$GzipError;
    if ( $type eq 'zlib' ) {
        $method = \&deflate;
        $error  = \$DeflateError;
    }

    my $msgz;
    &{$method}(\$message => \$msgz)
      or die "compress failed: ${$error}";

    return $msgz;
}

sub uncompress {
    my @p = validate_pos(
        @_,
        { type => SCALAR }
    );
    
    my $message = shift @p;
    
    my $msg_magic = substr $message, 0, 2;
    
    my $method;
    my $error;
    if ($ZLIB_MAGIC eq $msg_magic) {
        $method = \&inflate;
        $error  = \$InflateError;
    }
    elsif ($GZIP_MAGIC eq $msg_magic) {
        $method = \&gunzip;
        $error  = \$GunzipError;
    }
    else {
        #assume plain message
        return $message;
    }

    my $msg;
    &{$method}(\$message => \$msg)
      or die "uncompress failed: ${$error}";

    return $msg;
}

sub enchunk {
    my @p = validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR, default => 'wan' },
        { type => SCALAR, default => pack('L*', irand(),irand()) },
    );

    my ($message, $size, $message_id) = @p;

    if ( length $message_id != 8 ) {
        die "message id must be 8 bytes";
    }

    $size = parse_size($size);

    if ( $size > 0
         && length $message > $size
    ) {
        my @chunks;
        while (length $message) {
            push @chunks, substr $message, 0, $size, '';
        }

        my $n_chunks = scalar @chunks;
        die 'Message too big' if $n_chunks > 128;

        my $sequence_count = pack('C*', $n_chunks);

        my @chunks_w_header;
        my $sequence_number = 0;
        foreach my $chunk (@chunks) {
           push @chunks_w_header,
              $GELF_MSG_MAGIC
              . $message_id
              . pack('C*',$sequence_number++)
              . $sequence_count
              . $chunk;
        }

        return @chunks_w_header;
    }
    else {
         return ($message);
    }
}

sub dechunk {
    my @p = validate_pos(
        @_,
        { type => ARRAYREF },
        { type => HASHREF },
    );

    my ($accumulator, $chunk) = @_;

    if ( ! exists $chunk->{id}
           && exists $chunk->{sequence_number}
           && exists $chunk->{sequence_count}
           && exists $chunk->{data}
    ) {
        die 'malformed chunk';
    }

    if ($chunk->{sequence_number} > $chunk->{sequence_count} ) {
        die 'chunk sequence number > count';
    }

    $accumulator->[$chunk->{sequence_number}] = $chunk->{data};

    if ( (scalar grep {defined} @{$accumulator}) == $chunk->{sequence_count} ) {
        return join '', @{$accumulator};
    }
    else {
        return;
    }
}

sub is_chunked {
    my @p = validate_pos(
        @_,
        { type => SCALAR },
    );
    
    my $chunk = shift @p;
    
    return $GELF_MSG_MAGIC eq substr $chunk, 0, 2;
}

sub decode_chunk {
    my @p = validate_pos(
        @_,
        { type => SCALAR },
    );
    
    my $encoded_chunk = shift;

    if ( is_chunked($encoded_chunk) ) {
        
        my $id      = substr $encoded_chunk,  2, 8;
        my $seq_no  = unpack('C',  substr $encoded_chunk, 10, 1);
        my $seq_cnt = unpack('C',  substr $encoded_chunk, 11, 1);
        my $data    = substr $encoded_chunk, 12;
        
        return {
            id              => $id,
            sequence_number => $seq_no,
            sequence_count  => $seq_cnt,
            data            => $data,
        };
    }
    else {
        die "message not chunked";
    }
}

sub parse_level {
    my @p = validate_pos(
        @_,
        { type => SCALAR }
    );
    
    my $level = shift @p;

    if ( $level =~ $LEVEL_NAME_REGEX ) {
        return $LEVEL_NAME_TO_NUMBER{$1};
    }
    elsif ( $level =~ /^(?:0|1|2|3|4|5|6|7)$/ ) {
        return $level;
    }
    else {
        die "level must be between 0 and 7 or a valid log level string";
    }
}

sub parse_size {
    my @p = validate_pos(
        @_,
        {
            type      => SCALAR,
            callbacks => {
                compress_type => sub {
                    my $size = shift;
                    $size =~ /^(?:lan|wan|\d+)$/i
                        or die 'chunk size must be "lan", "wan", a positve integer, or 0 (no chunking)';
                },
            },
        },
    );

    my $size = lc(shift @p);

    # These default values below were determined by
    # examining the code for Graylog's implementation. See
    #  https://github.com/Graylog2/gelf-rb/blob/master/lib/gelf/notifier.rb#L62
    # I believe these are determined by likely MTU defaults
    #  and possible heasers like so...
    # WAN: 1500 - 8 b (UDP header) - 60 b (max IP header) - 12 b (chunking header) = 1420 b
    # LAN: 8192 - 8 b (UDP header) - 20 b (min IP header) - 12 b (chunking header) = 8152 b
    # Note that based on my calculation the Graylog LAN
    #  default may be 2 bytes too big (8154)
    # See http://stackoverflow.com/questions/14993000/the-most-reliable-and-efficient-udp-packet-size
    # For some discussion. I don't think this is an exact science!

    if ( $size eq 'wan' ) {
        $size = 1420;
    }
    elsif ( $size eq 'lan' ) {
        $size = 8152;
    }

    return $size;
}

1;
__END__

=encoding utf-8

=head1 NAME

Log::GELF::Util - Utility functions for Graylog's GELF format.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Log::GELF::Util is a collection of functions and data structures useful
when working with Graylog's GELF Format version 1.1. It strives to support
all of the features and options as described in the L<GELF
specification|http://docs.graylog.org/en/latest/pages/gelf.html>.

=head1 FUNCTIONS

=head2 validate_message( short_message => $ )

Returns a HASHREF representing the validated message with any defaulted
values added to the data structure.

Takes the following message parameters as per the GELF message
specification:

=over

=item short_message

Mandatory string, a short descriptive message

=item version

String, must be '1.1' which is the default.

=item host

String, defaults to hostname() from L<Sys::Hostname>.

=item timestamp

Timestamp, defaults to time() from L<Time::HiRes>.

=item level

Integer, equal to the standard syslog levels, default is 1 (ALERT).

=item facility

Deprecated, a warning will be issued.

=item line

Deprecated, a warning will be issued.

=item file

Deprecated, a warning will be issued.

=item _[additional_field]

Parameters prefixed with an underscore (_) will be treated as an additional
field. Allowed characters in field names are any word character (letter,
number, underscore), dashes and dots. As per the specification '_id' is
disallowed.

=back

=head2 encode( \% )

Accepts a HASHREF representing a GELF message. The message will be
validated with L</validate_message>.

Returns a JSON encoded string representing the message.

=head2 decode( $ )

Accepts a JSON encoded string representing the message. This will be
converted to a hashref and validated with L</validate_message>.

Returns a HASHREF representing the validated message with any defaulted
values added to the data structure.

=head2 compress( $ [, $] )

Accepts a string and compresses it. The second parameter is optional and
can take the value C<zlib> or C<gzip>, defaulting to C<gzip>.

Returns a compressed string.

=head2 uncompress( $ )

Accepts a string and uncompresses it. The compression method (C<gzip> or
C<zlib>) is determined automatically. Uncompressed strings are passed
through unaltered.

Returns an uncompressed string.

=head2 enchunk( $ [, $, $] )

Accepts an encoded message (JSON string) and chunks it according to the
GELF chunking protocol.

The optional second parameter is the maximum size of the chunks to produce,
this must be a positive integer or the special strings C<lan> or C<wan>,
see L</parse_size>. Defaults to C<wan>. A zero chunk size means no chunking
will be applied.

The optional third parameter is the message id used to identify associated
chunks. This must be 8 bytes. It defaults to 8 bytes of randomness generated
by L<Math::Random::MT>.

If the message size is greater than the maximum size then an array of
chunks is retuned, otherwise the message is retuned unaltered as the first
element of an array.

=head2 dechunk( \@, \% )

This facilitates reassembling a GELF message from a stream of chunks.

It accepts an ARRAYREF for accumulating the chunks and a HASHREF
representing a decoded message chunk as produced by L</decode_chunk>.

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

=head2 is_chunked( $ )

Accepts a string and returns a true value if it is a GELF message chunk.

=head2 decode_chunk( $ )

Accepts a GELF message chunk and returns an ARRAYREF representing the
unpacked chunk. Dies if the input is not a GELF chunk.

The message consists of the following keys:

 id
 sequence_number
 sequence_count
 data

=head2 parse_level( $ )

Accepts a C<syslog> style level in the form of a number (1-7) or a string
being one of C<emerg>, C<alert>, C<crit>, C<err>, C<warn>, C<notice>,
C<info>, or C<debug>. Dies upon invalid input.

The string forms may also be elongated and will still be accepted. For
example C<err> and C<error> are equivalent.

The associated syslog level is returned in numeric form.

=head2 parse_size( $ )

Accepts an integer specifying the chunk size or the special string values
C<lan> or C<wan> corresponding to 8154 or 1420 respectively. An explanation
of these values is in the code.

Returns the passed size or the value corresponding to the C<lan> or C<wan>.

L</parse_size> dies upon invalid input.

=head1 CONSTANTS

All Log::Gelf::Util constants are Readonly perl structures. You must use
sigils when referencing them. They can be imported individually and are
included when importing ':all';

=head2 $GELF_MSG_MAGIC

The magic number used to identify a GELF message chunk.

=head2 $ZLIB_MAGIC

The magic number used to identify a Zlib deflated message.

=head2 $GZIP_MAGIC

The magic number used to identify a gzipped message.

=head2 %LEVEL_NAME_TO_NUMBER

A HASH mapping the level names to numbers.

=head2 %LEVEL_NUMBER_TO_NAME

A HASH mapping the level numbers to names.

=head2 %GELF_MESSAGE_FIELDS

A HASH where each key is a valid core GELF message field name. Deprecated
fields are associated with a false value.

=head1 LICENSE

Copyright (C) Strategic Data.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Adam Clarke E<lt>adamc@strategicdata.com.auE<gt>

=cut
