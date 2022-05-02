package File::KDBX::Dumper::V4;
# ABSTRACT: Dump KDBX4 files

use warnings;
use strict;

use Crypt::Digest qw(digest_data);
use Crypt::Mac::HMAC qw(hmac);
use Encode qw(encode is_utf8);
use File::KDBX::Constants qw(:header :inner_header :compression :kdf :variant_map);
use File::KDBX::Error;
use File::KDBX::IO::Crypt;
use File::KDBX::IO::HmacBlock;
use File::KDBX::Util qw(:class :empty :load assert_64bit erase_scoped);
use IO::Handle;
use Scalar::Util qw(looks_like_number);
use boolean qw(:all);
use namespace::clean;

extends 'File::KDBX::Dumper';

our $VERSION = '0.901'; # VERSION

has _binaries_written => {}, is => 'ro';

sub _write_headers {
    my $self = shift;
    my $fh = shift;

    my $kdbx = $self->kdbx;
    my $headers = $kdbx->headers;
    my $buf = '';

    # Always write the standard AES KDF UUID, for compatibility
    local $headers->{+HEADER_KDF_PARAMETERS}->{+KDF_PARAM_UUID} = KDF_UUID_AES
        if $headers->{+HEADER_KDF_PARAMETERS}->{+KDF_PARAM_UUID} eq KDF_UUID_AES_CHALLENGE_RESPONSE;

    if (nonempty (my $comment = $headers->{+HEADER_COMMENT})) {
        $buf .= $self->_write_header($fh, HEADER_COMMENT, $comment);
    }
    for my $type (
        HEADER_CIPHER_ID,
        HEADER_COMPRESSION_FLAGS,
        HEADER_MASTER_SEED,
        HEADER_ENCRYPTION_IV,
        HEADER_KDF_PARAMETERS,
    ) {
        defined $headers->{$type} or throw "Missing value for required header: $type", type => $type;
        $buf .= $self->_write_header($fh, $type, $headers->{$type});
    }
    $buf .= $self->_write_header($fh, HEADER_PUBLIC_CUSTOM_DATA, $headers->{+HEADER_PUBLIC_CUSTOM_DATA})
        if defined $headers->{+HEADER_PUBLIC_CUSTOM_DATA} && keys %{$headers->{+HEADER_PUBLIC_CUSTOM_DATA}};
    $buf .= $self->_write_header($fh, HEADER_END);

    return $buf;
}

sub _write_header {
    my $self = shift;
    my $fh   = shift;
    my $type = shift;
    my $val  = shift // '';

    $type = to_header_constant($type);
    if ($type == HEADER_END) {
        # nothing
    }
    elsif ($type == HEADER_COMMENT) {
        $val = encode('UTF-8', $val);
    }
    elsif ($type == HEADER_CIPHER_ID) {
        my $size = length($val);
        $size == 16 or throw 'Invalid cipher UUID length', got => $size, expected => $size;
    }
    elsif ($type == HEADER_COMPRESSION_FLAGS) {
        $val = pack('L<', $val);
    }
    elsif ($type == HEADER_MASTER_SEED) {
        my $size = length($val);
        $size == 32 or throw 'Invalid master seed length', got => $size, expected => $size;
    }
    elsif ($type == HEADER_ENCRYPTION_IV) {
        # nothing
    }
    elsif ($type == HEADER_KDF_PARAMETERS) {
        $val = $self->_write_variant_dictionary($val, {
            KDF_PARAM_UUID()               => VMAP_TYPE_BYTEARRAY,
            KDF_PARAM_AES_ROUNDS()         => VMAP_TYPE_UINT64,
            KDF_PARAM_AES_SEED()           => VMAP_TYPE_BYTEARRAY,
            KDF_PARAM_ARGON2_SALT()        => VMAP_TYPE_BYTEARRAY,
            KDF_PARAM_ARGON2_PARALLELISM() => VMAP_TYPE_UINT32,
            KDF_PARAM_ARGON2_MEMORY()      => VMAP_TYPE_UINT64,
            KDF_PARAM_ARGON2_ITERATIONS()  => VMAP_TYPE_UINT64,
            KDF_PARAM_ARGON2_VERSION()     => VMAP_TYPE_UINT32,
            KDF_PARAM_ARGON2_SECRET()      => VMAP_TYPE_BYTEARRAY,
            KDF_PARAM_ARGON2_ASSOCDATA()   => VMAP_TYPE_BYTEARRAY,
        });
    }
    elsif ($type == HEADER_PUBLIC_CUSTOM_DATA) {
        $val = $self->_write_variant_dictionary($val);
    }
    elsif ($type == HEADER_INNER_RANDOM_STREAM_ID ||
           $type == HEADER_INNER_RANDOM_STREAM_KEY ||
           $type == HEADER_TRANSFORM_SEED ||
           $type == HEADER_TRANSFORM_ROUNDS ||
           $type == HEADER_STREAM_START_BYTES) {
        throw "Unexpected KDBX3 header: $type", type => $type;
    }
    elsif ($type == HEADER_COMMENT) {
        throw "Unexpected KDB header: $type", type => $type;
    }
    else {
        alert "Unknown header: $type", type => $type;
    }

    my $size = length($val);
    my $buf = pack('C L<', 0+$type, $size);

    $fh->print($buf, $val) or throw 'Failed to write header';

    return "$buf$val";
}

sub _intuit_variant_type {
    my $self = shift;
    my $variant = shift;

    if (isBoolean($variant)) {
        return VMAP_TYPE_BOOL;
    }
    elsif (looks_like_number($variant) && ($variant + 0) =~ /^\d+$/) {
        assert_64bit;
        my $neg = $variant < 0;
        my @b = unpack('L>2', pack('Q>', $variant));
        return VMAP_TYPE_INT64  if $b[0] && $neg;
        return VMAP_TYPE_UINT64 if $b[0];
        return VMAP_TYPE_INT32  if $neg;
        return VMAP_TYPE_UINT32;
    }
    elsif (is_utf8($variant)) {
        return VMAP_TYPE_STRING;
    }
    return VMAP_TYPE_BYTEARRAY;
}

sub _write_variant_dictionary {
    my $self = shift;
    my $dict = shift || {};
    my $types = shift || {};

    my $buf = '';

    $buf .= pack('S<', VMAP_VERSION);

    for my $key (sort keys %$dict) {
        my $val = $dict->{$key};

        my $type = $types->{$key} // $self->_intuit_variant_type($val);
        $buf .= pack('C', $type);

        if ($type == VMAP_TYPE_UINT32) {
            $val = pack('L<', $val);
        }
        elsif ($type == VMAP_TYPE_UINT64) {
            assert_64bit;
            $val = pack('Q<', $val);
        }
        elsif ($type == VMAP_TYPE_BOOL) {
            $val = pack('C', $val);
        }
        elsif ($type == VMAP_TYPE_INT32) {
            $val = pack('l', $val);
        }
        elsif ($type == VMAP_TYPE_INT64) {
            assert_64bit;
            $val = pack('q<', $val);
        }
        elsif ($type == VMAP_TYPE_STRING) {
            $val = encode('UTF-8', $val);
        }
        elsif ($type == VMAP_TYPE_BYTEARRAY) {
            # $val = substr($$buf, $pos, $vlen);
            # $val = [split //, $val];
        }
        else {
            throw 'Unknown variant dictionary value type', type => $type;
        }

        my ($klen, $vlen) = (length($key), length($val));
        $buf .= pack("L< a$klen L< a$vlen", $klen, $key, $vlen, $val);
    }

    $buf .= pack('C', VMAP_TYPE_END);

    return $buf;
}

sub _write_body {
    my $self = shift;
    my $fh   = shift;
    my $key  = shift;
    my $header_data = shift;
    my $kdbx = $self->kdbx;

    # assert all required headers present
    for my $field (
        HEADER_CIPHER_ID,
        HEADER_ENCRYPTION_IV,
        HEADER_MASTER_SEED,
    ) {
        defined $kdbx->headers->{$field} or throw "Missing header: $field";
    }

    my @cleanup;

    # write 32-byte checksum
    my $header_hash = digest_data('SHA256', $header_data);
    $fh->print($header_hash) or throw 'Failed to write header hash';

    $key = $kdbx->composite_key($key);
    my $transformed_key = $kdbx->kdf->transform($key);
    push @cleanup, erase_scoped $transformed_key;

    # write 32-byte HMAC for header
    my $hmac_key = digest_data('SHA512', $kdbx->headers->{master_seed}, $transformed_key, "\x01");
    push @cleanup, erase_scoped $hmac_key;
    my $header_hmac = hmac('SHA256',
        digest_data('SHA512', "\xff\xff\xff\xff\xff\xff\xff\xff", $hmac_key),
        $header_data,
    );
    $fh->print($header_hmac) or throw 'Failed to write header HMAC';

    $kdbx->key($key);

    # HMAC-block the rest of the stream
    $fh = File::KDBX::IO::HmacBlock->new($fh, key => $hmac_key);

    my $final_key = digest_data('SHA256', $kdbx->headers->{master_seed}, $transformed_key);
    push @cleanup, erase_scoped $final_key;

    my $cipher = $kdbx->cipher(key => $final_key);
    $fh = File::KDBX::IO::Crypt->new($fh, cipher => $cipher);

    my $compress = $kdbx->headers->{+HEADER_COMPRESSION_FLAGS};
    if ($compress == COMPRESSION_GZIP) {
        load_optional('IO::Compress::Gzip');
        $fh = IO::Compress::Gzip->new($fh,
            -Level => IO::Compress::Gzip::Z_BEST_COMPRESSION(),
            -TextFlag => 1,
        ) or throw "Failed to initialize compression library: $IO::Compress::Gzip::GzipError",
            error => $IO::Compress::Gzip::GzipError;
    }
    elsif ($compress != COMPRESSION_NONE) {
        throw "Unsupported compression ($compress)\n", compression_flags => $compress;
    }

    $self->_write_inner_headers($fh);

    local $self->{compress_datetimes} = 1;
    $self->_write_inner_body($fh, $header_hash);
}

sub _write_inner_headers {
    my $self = shift;
    my $fh   = shift;

    my $kdbx = $self->kdbx;
    my $headers = $kdbx->inner_headers;

    for my $type (
        INNER_HEADER_INNER_RANDOM_STREAM_ID,
        INNER_HEADER_INNER_RANDOM_STREAM_KEY,
    ) {
        defined $headers->{$type} or throw "Missing inner header: $type";
        $self->_write_inner_header($fh, $type => $headers->{$type});
    }

    $self->_write_binaries($fh);

    $self->_write_inner_header($fh, INNER_HEADER_END);
}

sub _write_inner_header {
    my $self = shift;
    my $fh   = shift;
    my $type = shift;
    my $val  = shift // '';

    my $buf = pack('C', $type);
    $fh->print($buf) or throw 'Failed to write inner header type';

    $type = to_inner_header_constant($type);
    if ($type == INNER_HEADER_END) {
        # nothing
    }
    elsif ($type == INNER_HEADER_INNER_RANDOM_STREAM_ID) {
        $val = pack('L<', $val);
    }
    elsif ($type == INNER_HEADER_INNER_RANDOM_STREAM_KEY) {
        # nothing
    }
    elsif ($type == INNER_HEADER_BINARY) {
        # nothing
    }

    $buf = pack('L<', length($val));
    $fh->print($buf) or throw 'Failed to write inner header value size';
    $fh->print($val) or throw 'Failed to write inner header value';
}

sub _write_binaries {
    my $self = shift;
    my $fh = shift;

    my $kdbx = $self->kdbx;

    my $new_ref = 0;
    my $written = $self->_binaries_written;

    my $entries = $kdbx->entries(history => 1);
    while (my $entry = $entries->next) {
        for my $key (keys %{$entry->binaries}) {
            my $binary = $entry->binaries->{$key};
            if (defined $binary->{ref} && defined $kdbx->binaries->{$binary->{ref}}) {
                $binary = $kdbx->binaries->{$binary->{ref}};
            }

            if (!defined $binary->{value}) {
                alert "Skipping binary which has no value: $key", key => $key;
                next;
            }

            my $hash = digest_data('SHA256', $binary->{value});
            if (defined $written->{$hash}) {
                # nothing
            }
            else {
                my $flags = 0;
                $flags &= INNER_HEADER_BINARY_FLAG_PROTECT if $binary->{protect};

                $self->_write_binary($fh, \$binary->{value}, $flags);
                $written->{$hash} = $new_ref++;
            }
        }
    }
}

sub _write_binary {
    my $self = shift;
    my $fh = shift;
    my $data = shift;
    my $flags = shift || 0;

    my $buf = pack('C', 0 + INNER_HEADER_BINARY);
    $fh->print($buf) or throw 'Failed to write inner header type';

    $buf = pack('L<', 1 + length($$data));
    $fh->print($buf) or throw 'Failed to write inner header value size';

    $buf = pack('C', $flags);
    $fh->print($buf) or throw 'Failed to write inner header binary flags';

    $fh->print($$data) or throw 'Failed to write inner header value';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Dumper::V4 - Dump KDBX4 files

=head1 VERSION

version 0.901

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
