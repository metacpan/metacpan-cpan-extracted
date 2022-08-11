package File::KDBX::Dumper::V3;
# ABSTRACT: Dump KDBX3 files

use warnings;
use strict;

use Crypt::Digest qw(digest_data);
use Encode qw(encode);
use File::KDBX::Constants qw(:header :compression);
use File::KDBX::Error;
use File::KDBX::IO::Crypt;
use File::KDBX::IO::HashBlock;
use File::KDBX::Util qw(:class :empty :int :load erase_scoped);
use IO::Handle;
use namespace::clean;

extends 'File::KDBX::Dumper';

our $VERSION = '0.905'; # VERSION

sub _write_headers {
    my $self = shift;
    my $fh = shift;

    my $kdbx = $self->kdbx;
    my $headers = $kdbx->headers;
    my $buf = '';

    # FIXME kinda janky - maybe add a "prepare" hook to massage the KDBX into the correct shape before we get
    # this far
    local $headers->{+HEADER_TRANSFORM_SEED} = $kdbx->transform_seed;
    local $headers->{+HEADER_TRANSFORM_ROUNDS} = $kdbx->transform_rounds;

    if (nonempty (my $comment = $headers->{+HEADER_COMMENT})) {
        $buf .= $self->_write_header($fh, HEADER_COMMENT, $comment);
    }
    for my $type (
        HEADER_CIPHER_ID,
        HEADER_COMPRESSION_FLAGS,
        HEADER_MASTER_SEED,
        HEADER_TRANSFORM_SEED,
        HEADER_TRANSFORM_ROUNDS,
        HEADER_ENCRYPTION_IV,
        HEADER_INNER_RANDOM_STREAM_KEY,
        HEADER_STREAM_START_BYTES,
        HEADER_INNER_RANDOM_STREAM_ID,
    ) {
        defined $headers->{$type} or throw "Missing value for required header: $type", type => $type;
        $buf .= $self->_write_header($fh, $type, $headers->{$type});
    }
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
        $val = "\r\n\r\n";
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
    elsif ($type == HEADER_TRANSFORM_SEED) {
        # nothing
    }
    elsif ($type == HEADER_TRANSFORM_ROUNDS) {
        $val = pack_Ql($val);
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
        $val = pack('L<', $val);
    }
    elsif ($type == HEADER_KDF_PARAMETERS ||
           $type == HEADER_PUBLIC_CUSTOM_DATA) {
        throw "Unexpected KDBX4 header: $type", type => $type;
    }
    elsif ($type == HEADER_COMMENT) {
        throw "Unexpected KDB header: $type", type => $type;
    }
    else {
        alert "Unknown header: $type", type => $type;
    }

    my $size = length($val);
    my $buf = pack('C S<', 0+$type, $size);

    $fh->print($buf, $val) or throw 'Failed to write header';

    return "$buf$val";
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
        HEADER_INNER_RANDOM_STREAM_KEY,
        HEADER_STREAM_START_BYTES,
    ) {
        defined $kdbx->headers->{$field} or throw "Missing $field";
    }

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

    $fh->print($kdbx->headers->{+HEADER_STREAM_START_BYTES})
        or throw 'Failed to write start bytes';

    $kdbx->key($key);

    $fh = File::KDBX::IO::HashBlock->new($fh);

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

    my $header_hash = digest_data('SHA256', $header_data);
    $self->_write_inner_body($fh, $header_hash);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Dumper::V3 - Dump KDBX3 files

=head1 VERSION

version 0.905

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
