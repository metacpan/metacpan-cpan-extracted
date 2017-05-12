package Memcached::Client::Compressor::Gzip;
BEGIN {
  $Memcached::Client::Compressor::Gzip::VERSION = '2.01';
}
#ABSTRACT: Implements Memcached Compression using Gzip

use bytes;
use strict;
use warnings;
use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Compressor};

use constant +{
    HAVE_ZLIB => eval { require Compress::Zlib; 1 },
    F_COMPRESS => 2,
    COMPRESS_SAVINGS => 0.20
};

sub decompress {
    my ($self, $data, $flags) = @_;

    return unless defined $data;

    $flags ||= 0;

    if ($flags & F_COMPRESS && HAVE_ZLIB) {
        $self->log ("Uncompressing data") if DEBUG;
        $data = Compress::Zlib::memGunzip ($data);
    }

    return ($data, $flags);
}

sub compress {
    my ($self, $data, $flags) = @_;

    $self->log ("Entering compress") if DEBUG;
    return unless defined $data;

    $self->log ("Have data") if DEBUG;
    my $len = bytes::length ($data);

    $self->log ("Checking for Zlib") if DEBUG;

    if (HAVE_ZLIB) {

        my $compressable = $self->{compress_threshold} && $len >= $self->{compress_threshold};

        if ($compressable) {
            $self->log ("Compressing data") if DEBUG;
            my $c_val = Compress::Zlib::memGzip ($data);
            my $c_len = bytes::length ($c_val);

            if ($c_len < $len * (1 - COMPRESS_SAVINGS)) {
                $self->log ("Compressing is a win") if DEBUG;
                $data = $c_val;
                $flags |= F_COMPRESS;
            }
        }
    }

    return ($data, $flags);
}

1;

__END__
=pod

=head1 NAME

Memcached::Client::Compressor::Gzip - Implements Memcached Compression using Gzip

=head1 VERSION

version 2.01

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

