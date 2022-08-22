package File::KDBX::Loader::V4;
# ABSTRACT: Load KDBX4 files

# magic
# headers
# headers checksum
# headers hmac
# body
#   HMAC(
#     CRYPT(
#       COMPRESS(
#         xml
#       )
#     )
#   )

use warnings;
use strict;

use Crypt::Digest qw(digest_data);
use Crypt::Mac::HMAC qw(hmac);
use Encode qw(decode);
use File::KDBX::Constants qw(:header :inner_header :variant_map :compression);
use File::KDBX::Error;
use File::KDBX::Util qw(:class :int :io :load erase_scoped);
use File::KDBX::IO::Crypt;
use File::KDBX::IO::HmacBlock;
use boolean;
use namespace::clean;

extends 'File::KDBX::Loader';

our $VERSION = '0.906'; # VERSION

sub _read_header {
    my $self = shift;
    my $fh = shift;

    read_all $fh, my $buf, 5 or throw 'Malformed header field, expected header type and size';
    my ($type, $size) = unpack('C L<', $buf);

    my $val;
    if (0 < $size) {
        read_all $fh, $val, $size or throw 'Expected header value', type => $type, size => $size;
        $buf .= $val;
    }

    $type = to_header_constant($type);
    if ($type == HEADER_END) {
        # done
    }
    elsif ($type == HEADER_COMMENT) {
        $val = decode('UTF-8', $val);
    }
    elsif ($type == HEADER_CIPHER_ID) {
        $size == 16 or throw 'Invalid cipher UUID length', got => $size, expected => $size;
    }
    elsif ($type == HEADER_COMPRESSION_FLAGS) {
        $val = unpack('L<', $val);
    }
    elsif ($type == HEADER_MASTER_SEED) {
        $size == 32 or throw 'Invalid master seed length', got => $size, expected => $size;
    }
    elsif ($type == HEADER_ENCRYPTION_IV) {
        # nothing
    }
    elsif ($type == HEADER_KDF_PARAMETERS) {
        open(my $dict_fh, '<', \$val);
        $val = $self->_read_variant_dictionary($dict_fh);
    }
    elsif ($type == HEADER_PUBLIC_CUSTOM_DATA) {
        open(my $dict_fh, '<', \$val);
        $val = $self->_read_variant_dictionary($dict_fh);
    }
    elsif ($type == HEADER_INNER_RANDOM_STREAM_ID ||
           $type == HEADER_INNER_RANDOM_STREAM_KEY ||
           $type == HEADER_TRANSFORM_SEED ||
           $type == HEADER_TRANSFORM_ROUNDS ||
           $type == HEADER_STREAM_START_BYTES) {
        throw "Unexpected KDBX3 header: $type", type => $type;
    }
    else {
        alert "Unknown header: $type", type => $type;
    }

    return wantarray ? ($type => $val, $buf) : $buf;
}

sub _read_variant_dictionary {
    my $self = shift;
    my $fh   = shift;

    read_all $fh, my $buf, 2 or throw 'Failed to read variant dictionary version';
    my ($version) = unpack('S<', $buf);
    VMAP_VERSION == ($version & VMAP_VERSION_MAJOR_MASK)
        or throw 'Unsupported variant dictionary version', version => $version;

    my %dict;

    while (1) {
        read_all $fh, $buf, 1 or throw 'Failed to read variant type';
        my ($type) = unpack('C', $buf);
        last if $type == VMAP_TYPE_END; # terminating null

        read_all $fh, $buf, 4 or throw 'Failed to read variant key size';
        my ($klen) = unpack('L<', $buf);

        read_all $fh, my $key, $klen or throw 'Failed to read variant key';

        read_all $fh, $buf, 4 or throw 'Failed to read variant size';
        my ($vlen) = unpack('L<', $buf);

        read_all $fh, my $val, $vlen or throw 'Failed to read variant';

        if ($type == VMAP_TYPE_UINT32) {
            ($val) = unpack('L<', $val);
        }
        elsif ($type == VMAP_TYPE_UINT64) {
            ($val) = unpack_Ql($val);
        }
        elsif ($type == VMAP_TYPE_BOOL) {
            ($val) = unpack('C', $val);
            $val = boolean($val);
        }
        elsif ($type == VMAP_TYPE_INT32) {
            ($val) = unpack('l<', $val);
        }
        elsif ($type == VMAP_TYPE_INT64) {
            ($val) = unpack_ql($val);
        }
        elsif ($type == VMAP_TYPE_STRING) {
            $val = decode('UTF-8', $val);
        }
        elsif ($type == VMAP_TYPE_BYTEARRAY) {
            # nothing
        }
        else {
            throw 'Unknown variant type', type => $type;
        }
        $dict{$key} = $val;
    }

    return \%dict;
}

sub _read_body {
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
        defined $kdbx->headers->{$field} or throw "Missing $field";
    }

    my @cleanup;

    # checksum check
    read_all $fh, my $header_hash, 32 or throw 'Failed to read header hash';
    my $got_header_hash = digest_data('SHA256', $header_data);
    $got_header_hash eq $header_hash
        or throw 'Data is corrupt (header checksum mismatch)',
            got => $got_header_hash, expected => $header_hash;

    $key = $kdbx->composite_key($key);
    my $transformed_key = $kdbx->kdf->transform($key);
    push @cleanup, erase_scoped $transformed_key;

    # authentication check
    read_all $fh, my $header_hmac, 32 or throw 'Failed to read header HMAC';
    my $hmac_key = digest_data('SHA512', $kdbx->headers->{master_seed}, $transformed_key, "\x01");
    push @cleanup, erase_scoped $hmac_key;
    my $got_header_hmac = hmac('SHA256',
        digest_data('SHA512', "\xff\xff\xff\xff\xff\xff\xff\xff", $hmac_key),
        $header_data,
    );
    $got_header_hmac eq $header_hmac
        or throw "Invalid credentials or data is corrupt (header HMAC mismatch)\n",
            got => $got_header_hmac, expected => $header_hmac;

    $kdbx->key($key);

    $fh = File::KDBX::IO::HmacBlock->new($fh, key => $hmac_key);

    my $final_key = digest_data('SHA256', $kdbx->headers->{master_seed}, $transformed_key);
    push @cleanup, erase_scoped $final_key;

    my $cipher = $kdbx->cipher(key => $final_key);
    $fh = File::KDBX::IO::Crypt->new($fh, cipher => $cipher);

    my $compress = $kdbx->headers->{+HEADER_COMPRESSION_FLAGS};
    if ($compress == COMPRESSION_GZIP) {
        load_optional('IO::Uncompress::Gunzip');
        $fh = IO::Uncompress::Gunzip->new($fh)
            or throw "Failed to initialize compression library: $IO::Uncompress::Gunzip::GunzipError",
                error => $IO::Uncompress::Gunzip::GunzipError;
    }
    elsif ($compress != COMPRESSION_NONE) {
        throw "Unsupported compression ($compress)\n", compression_flags => $compress;
    }

    $self->_read_inner_headers($fh);
    $self->_read_inner_body($fh);
}

sub _read_inner_headers {
    my $self = shift;
    my $fh   = shift;

    while (my ($type, $val) = $self->_read_inner_header($fh)) {
        last if $type == INNER_HEADER_END;
    }
}

sub _read_inner_header {
    my $self = shift;
    my $fh   = shift;
    my $kdbx = $self->kdbx;

    read_all $fh, my $buf, 5 or throw 'Expected inner header type and size';
    my ($type, $size) = unpack('C L<', $buf);

    my $val;
    if (0 < $size) {
        read_all $fh, $val, $size or throw 'Expected inner header value', type => $type, size => $size;
    }

    $type = to_inner_header_constant($type) // $type;
    if ($type == INNER_HEADER_END) {
        # nothing
    }
    elsif ($type == INNER_HEADER_INNER_RANDOM_STREAM_ID) {
        $val = unpack('L<', $val);
        $kdbx->inner_headers->{$type} = $val;
    }
    elsif ($type == INNER_HEADER_INNER_RANDOM_STREAM_KEY) {
        $kdbx->inner_headers->{$type} = $val;
    }
    elsif ($type == INNER_HEADER_BINARY) {
        my $msize = $size - 1;
        my ($flags, $data) = unpack("C a$msize", $val);
        my $id = scalar keys %{$kdbx->binaries};
        $kdbx->binaries->{$id} = {
            value   => $data,
            $flags & INNER_HEADER_BINARY_FLAG_PROTECT ? (protect => true) : (),
        };
    }
    else {
        alert "Ignoring unknown inner header type ($type)", type => $type, size => $size, value => $val;
        return wantarray ? ($type => $val) : $type;
    }

    return wantarray ? ($type => $val) : $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Loader::V4 - Load KDBX4 files

=head1 VERSION

version 0.906

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
