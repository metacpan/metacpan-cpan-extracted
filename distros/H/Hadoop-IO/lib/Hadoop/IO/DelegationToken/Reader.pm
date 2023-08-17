package Hadoop::IO::DelegationToken::Reader;
$Hadoop::IO::DelegationToken::Reader::VERSION = '0.003';
use 5.010;
use strict;
use warnings;
use parent qw( Exporter );

use constant {
    TOKEN_STORAGE_MAGIC   => 'HDTS',
    TOKEN_STORAGE_VERSION => 0,
};

use Carp qw( croak );

use namespace::clean;

our @EXPORT_OK = qw(
    parseTokenStorageStream
    vlong
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub parseTokenStorageStream {
    my ($fh) = @_;

    my $buf;
    croak "Bad header found in token storage"
      if read( $fh, $buf, 4 ) && $buf ne TOKEN_STORAGE_MAGIC;
    croak sprintf "Unknown version %d version in token storage", unpack( 'C', $buf )
      if read( $fh, $buf, 1 ) && unpack( 'C', $buf ) != TOKEN_STORAGE_VERSION;

    # read the tokens
    my %token;
    for ( 1 .. _read_vint( $fh ) ) {
        read( $fh, my $alias, _read_vint($fh) );
        read( $fh, my $identifier, _read_vint($fh) );
        read( $fh, my $password, _read_vint($fh) );
        read( $fh, my $kind,    _read_vint($fh) );
        read( $fh, my $service, _read_vint($fh) );
        $token{$alias} = {
            identifier => $identifier,
            password   => $password,
            kind       => $kind,
            service    => $service,
        };
    }

    # read the secrets
    my %secret;
    for ( 1 .. _read_vint( $fh ) ) {
        read( $fh, my $alias, _read_vint($fh) );
        read( $fh, my $secret, _read_vint($fh) );
        $secret{$alias} = $secret;
    }

    return { token => \%token, secret => \%secret };
}

sub _read_vint {
    my ($fh) = @_;
    my $n = _read_vlong($fh);
    if ( $n <= 2147483647 && $n >= -2147483648 ) { return $n; }
    else { die "value too long to fit in integer"; }
}

sub _read_vlong {
    my ($fh) = @_;
    my $buf;

    # For -112 <= i <= 127, only one byte is used with the actual value.
    # For other values of i, the first byte value indicates whether the
    # long is positive or negative, and the number of bytes that follow.
    # If the first byte value v is between -113 and -120, the following
    # long is positive, with number of bytes that follow are -(v+112).
    # If the first byte value v is between -121 and -128, the following
    # long is negative, with number of bytes that follow are -(v+120).
    # Bytes are stored in the high-non-zero-byte-first order.
    #
    # https://github.com/apache/hadoop/blob/branch-2.8.2/hadoop-common-project/hadoop-common/src/main/java/org/apache/hadoop/io/WritableUtils.java#L307

    #  first byte of a vint/vlong to determine the number of bytes
    read( $fh, $buf, 1 ) or die 'TODO';
    my $size = _decode_size($buf);
    my $val  = unpack( 'c', $buf );

    if ( $size == 1 ) { return $val; }
    else { # build the Java long from bytes
        read( $fh, $buf, $size ) or die 'TODO';
        my $n = 0;
        for my $byte ( unpack( 'c*', $buf ) ) {
            $n <<= 8;
            $n |= ( $byte & 255 );
        }

        # negative?
        return $val < -120 || ( $val >= -112 && $val <= 0 ) ? ~$n : $n;
    }
}

sub vlong {
    my ($long) = @_;
    if ( $long >= -112 && $long <= 127 ) { return pack( 'c', $long ); }
    else {
       if ( $long < 0 ) { $long = ~$long }
       my @bytes = unpack( 'C*', pack( 'q', $long ) );
       pop @bytes while !$bytes[-1];
       return pack( 'C*', @bytes );
   }
}

sub _decode_size {
    my ($byte) = @_;
    my $int = unpack( 'c', $byte );
    return ( $int >= -112 )
      ? 1
      : ( ( $int < -120 ) ? ( -119 - $int ) : ( -111 - $int ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::IO::DelegationToken::Reader

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use HHadoop::IO::DelegationToken::Reader qw( parseTokenStorageStream );
    open my $fh, '<', $file or die "Can't open $file for reading: $!";
    binmode($fh);
    my $token = parseTokenStorageStream( $fh );

=head1 DESCRIPTION

Hadoop::Oozie::DelegationTokenContainer parses token container files
produced by Hadoop, and can produce the base64 tokens used in REST
queries.

=head1 NAME

Hadoop::IO::DelegationToken::Reader - Perl interface to Hadoop delegation token file format

=head1 FUNCTIONS

=head2 parseTokenStorageStream

=head2 vlong

=head1 AUTHORS

=over 4

=item *

Philippe Bruhat

=item *

Sabbir Ahmed

=item *

Somesh Malviya

=item *

Vikentiy Fesunov

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
