package Image::TextMode::Reader::Tundra;

use Moo;

extends 'Image::TextMode::Reader';

sub _read {
    my ( $self, $image, $fh, $options ) = @_;

    my ( $buffer, %header );
    read( $fh, $buffer, 1 );
    $header{ int_id } = unpack( 'C', $buffer );

    read( $fh, $buffer, 8 );
    $header{ id } = unpack( 'A8', $buffer );

    $image->header( \%header );

    my $width = $options->{ width } || 80;
    my $pal = Image::TextMode::Palette->new;

    my ( $x, $y, $attr, $fg, $bg, $pal_index ) = ( 0 ) x 6;
    $pal->colors->[ $pal_index++ ] = [ 0, 0, 0 ];

    while ( read( $fh, $buffer, 1 ) ) {
        last if tell( $fh ) > $options->{ filesize };

        my $command = ord( $buffer );

        if ( $command == 1 ) {    # position
            read( $fh, $buffer, 8 );
            ( $y, $x ) = unpack( 'N*', $buffer );
            next;
        }

        my $char;

        if ( $command == 2 ) {    # fg
            read( $fh, $char,   1 );
            read( $fh, $buffer, 4 );
            my $rgb = unpack( 'N', $buffer );
            $fg = $pal_index++;
            $pal->colors->[ $fg ] = [
                ( $rgb >> 16 ) & 0x000000ff,
                ( $rgb >> 8 ) & 0x000000ff,
                $rgb & 0x000000ff,
            ];
        }
        elsif ( $command == 4 ) {    # bg
            read( $fh, $char,   1 );
            read( $fh, $buffer, 4 );
            my $rgb = unpack( 'N', $buffer );
            $bg = $pal_index++;
            $pal->colors->[ $bg ] = [
                ( $rgb >> 16 ) & 0x000000ff,
                ( $rgb >> 8 ) & 0x000000ff,
                $rgb & 0x000000ff,
            ];
        }
        elsif ( $command == 6 ) {    # fg + bg
            read( $fh, $char,   1 );
            read( $fh, $buffer, 8 );
            my @rgb = unpack( 'N*', $buffer );
            $fg = $pal_index++;
            $pal->colors->[ $fg ] = [
                ( $rgb[ 0 ] >> 16 ) & 0x000000ff,
                ( $rgb[ 0 ] >> 8 ) & 0x000000ff,
                $rgb[ 0 ] & 0x000000ff,
            ];
            $bg = $pal_index++;
            $pal->colors->[ $bg ] = [
                ( $rgb[ 1 ] >> 16 ) & 0x000000ff,
                ( $rgb[ 1 ] >> 8 ) & 0x000000ff,
                $rgb[ 1 ] & 0x000000ff,
            ];
        }

        if ( !$char ) {
            $char = chr( $command );
        }

        $image->putpixel( { char => $char, fg => $fg, bg => $bg }, $x, $y );
        $x++;

        if ( $x == $width ) {
            $x = 0;
            $y++;
        }
    }

    $image->palette( $pal );

    return $image;
}

=head1 NAME

Image::TextMode::Reader::Tundra - Reads Tundra files

=head1 DESCRIPTION

Provides reading capabilities for the Tundra format.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
