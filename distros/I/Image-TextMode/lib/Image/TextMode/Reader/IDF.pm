package Image::TextMode::Reader::IDF;

use Moo;

extends 'Image::TextMode::Reader';

my $header_template = 'A4 v v v v';
my @header_fields   = qw( id x0 y0 x1 y1 );

sub _read {
    my ( $self, $image, $fh, $options ) = @_;

    my $buffer;
    read( $fh, $buffer, 12 );

    my %header;
    @header{ @header_fields } = unpack( $header_template, $buffer );

    $image->header( \%header );

    # font and palette data are stored at the bottom of the file
    seek( $fh, -48 - 4096, 2 );
    if ( $image->has_sauce ) {
        my $s = $image->sauce;
        seek( $fh, -129 - ( $s->comment_count ? 5 + 64 * $s->comment_count : 0 ), 1 );
    }

    my $max = tell( $fh );

    read( $fh, $buffer, 4096 );
    _parse_font( $image, $buffer );

    read( $fh, $buffer, 48 );
    _parse_palette( $image, $buffer );

    seek( $fh, 12, 0 );
    my ( $x, $y ) = ( 0, 0 );
    my $width = $image->header->{ x1 };
    while ( tell $fh < $max ) {
        read( $fh, $buffer, 2 );
        my $info = unpack( 'v', $buffer );

        my $len = 1;
        if ( $info == 1 ) {
            read( $fh, $info, 2 );
            $len = unpack( 'v', $info ) & 255;
            read( $fh, $buffer, 2 );
        }

        my @data = unpack( 'aC', $buffer );
        for ( 1 .. $len ) {
            $image->putpixel( { char => $data[ 0 ], attr => $data[ 1 ] },
                $x, $y );
            $x++;
            if ( $x > $width ) {
                $x = 0;
                $y++;
            }
        }
    }

    return $image;
}

sub _parse_palette {
    my ( $image, $data ) = @_;

    my @pal = unpack( 'C*', $data );
    my @colors;
    for ( 0 .. 15 ) {
        my $offset = $_ * 3;
        push @colors, [ map { $_ << 2 | $_ >> 4 } @pal[ $offset .. $offset + 2 ] ],;
    }

    $image->palette(
        Image::TextMode::Palette->new( { colors => \@colors } ) );
}

sub _parse_font {
    my ( $image, $data ) = @_;
    my $height = 16;
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

=head1 NAME

Image::TextMode::Reader::IDF - Reads IDF files

=head1 DESCRIPTION

Provides reading capabilities for the IDF format.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
