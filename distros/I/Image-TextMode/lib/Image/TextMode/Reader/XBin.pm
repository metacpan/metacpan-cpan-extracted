package Image::TextMode::Reader::XBin;

use Moo;
use Carp 'croak';

extends 'Image::TextMode::Reader';

# Header byte constants
my $PALETTE          = 1;
my $FONT             = 2;
my $COMPRESSED       = 4;
my $NON_BLINK        = 8;
my $FIVETWELVE_CHARS = 16;

# Compression type constants
my $NO_COMPRESSION        = 0;
my $CHARACTER_COMPRESSION = 64;
my $ATTRIBUTE_COMPRESSION = 128;
my $FULL_COMPRESSION      = 192;

# Compression byte constants
my $COMPRESSION_TYPE    = 192;
my $COMPRESSION_COUNTER = 63;

my $header_template = 'A4 C v v C C';
my $eof_char        = chr( 26 );
my @header_fields   = qw( id eofchar width height fontsize flags );

sub _read {
    my ( $self, $image, $fh, $options ) = @_;

    my $headerdata;
    my $headerlength = read( $fh, $headerdata, 11 );

    # does it start with the right data?
    croak 'Not an XBin file.'
        unless $headerlength == 11 and $headerdata =~ m{^XBIN$eof_char}s;

    # parse header data
    _read_header( $image, $headerdata );

    if ( $image->header->{ flags } & $PALETTE ) {
        my $paldata;
        read( $fh, $paldata, 48 );
        _parse_palette( $image, $paldata );
    }

    if ( $image->header->{ flags } & $FONT ) {
        my $fontsize = $image->header->{ fontsize };
        my $chars    = $fontsize
            * ( $image->header->{ flags } & $FIVETWELVE_CHARS ? 512 : 256 );
        my $fontdata;
        read( $fh, $fontdata, $chars );
        _parse_font( $image, $fontdata );
    }

    if ( $image->header->{ flags } & $COMPRESSED ) {
        _parse_compressed( $image, $fh );
    }
    else {
        _parse_uncompressed( $image, $fh );
    }

    return $image;
}

sub _read_header {
    my ( $image, $content ) = @_;

    my %header;
    @header{ @header_fields } = unpack( $header_template, $content );

    $image->header( \%header );
}

sub _parse_font {
    my ( $image, $data ) = @_;
    my $height = $image->header->{ fontsize };
    my @chars;

    for ( 0 .. ( length( $data ) / $height ) - 1 ) {
        push @chars,
            [ unpack( 'C*', substr( $data, $_ * $height, $height ) ) ];
    }

    $image->font(
        Image::TextMode::Font->new(
            {   width  => 8,
                height => $height,
                chars  => \@chars,
            }
        )
    );
}

sub _parse_palette {
    my ( $image, $data ) = @_;

    my @values = unpack( 'C*', $data );
    my @palette;

    for my $i ( 0 .. @values / 3 - 1 ) {
        my $offset = $i * 3;
        $palette[ $i ] = [
            $values[ $offset ] << 2 | $values[ $offset ] >> 4,
            $values[ $offset + 1 ] << 2 | $values[ $offset + 1 ] >> 4,
            $values[ $offset + 2 ] << 2 | $values[ $offset + 2 ] >> 4,
        ];
    }

    $image->palette(
        Image::TextMode::Palette->new( { colors => \@palette } ) );
}

sub _parse_compressed {
    my ( $image, $fh ) = @_;

    my $x      = 0;
    my $y      = 0;
    my $width  = $image->header->{ width };
    my $height = $image->header->{ height };
    my $info;

    READ: while ( read( $fh, $info, 1 ) ) {
        $info = unpack( 'C', $info );

        my $type    = $info & $COMPRESSION_TYPE;
        my $counter = ( $info & $COMPRESSION_COUNTER ) + 1;

        my ( $char, $attr );
        while ( $counter-- ) {
            if ( $type == $NO_COMPRESSION ) {
                read( $fh, $char, 1 );
                read( $fh, $attr, 1 );
            }
            elsif ( $type == $CHARACTER_COMPRESSION ) {
                read( $fh, $char, 1 ) if !defined $char;
                read( $fh, $attr, 1 );
            }
            elsif ( $type == $ATTRIBUTE_COMPRESSION ) {
                read( $fh, $attr, 1 ) if !defined $attr;
                read( $fh, $char, 1 );
            }
            else {    # $FULL_COMPRESSION
                read( $fh, $char, 1 ) if !defined $char;
                read( $fh, $attr, 1 ) if !defined $attr;
            }

            my $pchar = unpack( 'a', $char );
            $image->putpixel(
                {   char => length $pchar ? $pchar : ' ',
                    attr => scalar unpack( 'C', $attr )
                },
                $x, $y,
            );

            $x++;
            if ( $x == $width ) {
                $x = 0;
                $y++;
                last READ if $y == $height;
            }
        }
    }
}

sub _parse_uncompressed {
    my ( $image, $fh ) = @_;

    my ( $x, $y ) = ( 0, 0 );
    my $chardata;
    my $width  = $image->header->{ width };
    my $height = $image->header->{ height };
    while ( read( $fh, $chardata, 2 ) ) {
        my @data = unpack( 'aC', $chardata );

        $image->putpixel( { char => $data[ 0 ], attr => $data[ 1 ] },
            $x, $y, );

        $x++;
        if ( $x == $width ) {
            $x = 0;
            $y++;
            last if $y == $height;
        }
    }
}

=head1 NAME

Image::TextMode::Reader::XBin - Reads XBin files

=head1 DESCRIPTION

Provides reading capabilities for the XBin format.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
