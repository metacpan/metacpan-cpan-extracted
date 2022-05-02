package File::KDBX::Loader::V3;
# ABSTRACT: Load KDBX3 files

# magic
# headers
# body
#   CRYPT(
#     start bytes
#     HASH(
#       COMPRESS(
#         xml
#       )
#     )
#   )

use warnings;
use strict;

use Crypt::Digest qw(digest_data);
use Encode qw(decode);
use File::KDBX::Constants qw(:header :compression :kdf);
use File::KDBX::Error;
use File::KDBX::IO::Crypt;
use File::KDBX::IO::HashBlock;
use File::KDBX::Util qw(:class :io :load assert_64bit erase_scoped);
use namespace::clean;

extends 'File::KDBX::Loader';

our $VERSION = '0.901'; # VERSION

sub _read_header {
    my $self = shift;
    my $fh = shift;

    read_all $fh, my $buf, 3 or throw 'Malformed header field, expected header type and size';
    my ($type, $size) = unpack('C S<', $buf);

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
    elsif ($type == HEADER_TRANSFORM_SEED) {
        # nothing
    }
    elsif ($type == HEADER_TRANSFORM_ROUNDS) {
        assert_64bit;
        $val = unpack('Q<', $val);
    }
    elsif ($type == HEADER_ENCRYPTION_IV) {
        # nothing
    }
    elsif ($type == HEADER_INNER_RANDOM_STREAM_KEY) {
        # nothing
    }
    elsif ($type == HEADER_STREAM_START_BYTES) {
        # nothing
    }
    elsif ($type == HEADER_INNER_RANDOM_STREAM_ID) {
        $val = unpack('L<', $val);
    }
    elsif ($type == HEADER_KDF_PARAMETERS ||
           $type == HEADER_PUBLIC_CUSTOM_DATA) {
        throw "Unexpected KDBX4 header: $type", type => $type;
    }
    else {
        alert "Unknown header: $type", type => $type;
    }

    return wantarray ? ($type => $val, $buf) : $buf;
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
        HEADER_INNER_RANDOM_STREAM_KEY,
        HEADER_STREAM_START_BYTES,
    ) {
        defined $kdbx->headers->{$field} or throw "Missing $field";
    }

    $kdbx->kdf_parameters({
        KDF_PARAM_UUID()        => KDF_UUID_AES,
        KDF_PARAM_AES_ROUNDS()  => delete $kdbx->headers->{+HEADER_TRANSFORM_ROUNDS},
        KDF_PARAM_AES_SEED()    => delete $kdbx->headers->{+HEADER_TRANSFORM_SEED},
    });

    my $master_seed = $kdbx->headers->{+HEADER_MASTER_SEED};

    my @cleanup;
    $key = $kdbx->composite_key($key);

    my $response = $key->challenge($master_seed);
    push @cleanup, erase_scoped $response;

    my $transformed_key = $kdbx->kdf->transform($key);
    push @cleanup, erase_scoped $transformed_key;

    my $final_key = digest_data('SHA256', $master_seed, $response, $transformed_key);
    push @cleanup, erase_scoped $final_key;

    my $cipher = $kdbx->cipher(key => $final_key);
    $fh = File::KDBX::IO::Crypt->new($fh, cipher => $cipher);

    read_all $fh, my $start_bytes, 32 or throw 'Failed to read starting bytes';

    my $expected_start_bytes = $kdbx->headers->{stream_start_bytes};
    $start_bytes eq $expected_start_bytes
        or throw "Invalid credentials or data is corrupt (wrong starting bytes)\n",
            got => $start_bytes, expected => $expected_start_bytes, headers => $kdbx->headers;

    $kdbx->key($key);

    $fh = File::KDBX::IO::HashBlock->new($fh);

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

    $self->_read_inner_body($fh);
    close($fh);

    if (my $header_hash = $kdbx->meta->{header_hash}) {
        my $got_header_hash = digest_data('SHA256', $header_data);
        $header_hash eq $got_header_hash
            or throw 'Header hash does not match', got => $got_header_hash, expected => $header_hash;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Loader::V3 - Load KDBX3 files

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
