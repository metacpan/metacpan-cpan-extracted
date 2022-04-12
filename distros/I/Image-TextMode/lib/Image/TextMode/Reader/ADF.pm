package Image::TextMode::Reader::ADF;

use Moo;

extends 'Image::TextMode::Reader';

my @color_idx = ( 0, 1, 2, 3, 4, 5, 20, 7, 56, 57, 58, 59, 60, 61, 62, 63 );

sub _read {
    my ( $self, $image, $fh, $options ) = @_;

    my $version;
    read( $fh, $version, 1 );
    $version = unpack( 'C', $version );
    $image->header( { version => $version } );

    my $paldata;
    read( $fh, $paldata, 192 );
    _parse_palette( $image, $paldata );

    my $fontdata;
    read( $fh, $fontdata, 4096 );
    _parse_font( $image, $fontdata );

    my ( $x, $y ) = ( 0, 0 );
    my $chardata;
    while ( read( $fh, $chardata, 2 ) ) {
        my @data = unpack( 'aC', $chardata );
        last if tell( $fh ) > $options->{ filesize } || $data[ 0 ] eq chr( 26 );
        $image->putpixel( { char => $data[ 0 ], attr => $data[ 1 ] }, $x,
            $y );

        $x++;
        if ( $x == 80 ) {
            $x = 0;
            $y++;
        }
    }

    return $image;
}

sub _parse_palette {
    my ( $image, $data ) = @_;

    my @pal = unpack( 'C*', $data );
    my @colors;
    for ( @color_idx ) {
        my $offset = $_ * 3;
        push @colors, [ map { $_ << 2 | $_ >> 4 } @pal[ $offset .. $offset + 2 ] ];
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

Image::TextMode::Reader::ADF - Reads ADF files

=head1 DESCRIPTION

Provides reading capabilities for the ADF format.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
