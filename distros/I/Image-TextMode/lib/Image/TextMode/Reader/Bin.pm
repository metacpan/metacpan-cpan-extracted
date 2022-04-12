package Image::TextMode::Reader::Bin;

use Moo;

extends 'Image::TextMode::Reader';

sub _read {
    my ( $self, $image, $fh, $options ) = @_;

    if ( $image->has_sauce ) {
        $image->render_options->{ blink_mode } = ($image->sauce->flags_id & 1) ^ 1;
    }

    my $width = $options->{ width } || 160;
    my ( $x, $y ) = ( 0, 0 );
    my $eof = chr( 26 );
    my $chardata;
    while ( read( $fh, $chardata, 2 ) ) {
        my @data = unpack( 'aC', $chardata );
        last if tell( $fh ) > $options->{ filesize } || $data[ 0 ] eq $eof;
        $image->putpixel( { char => $data[ 0 ], attr => $data[ 1 ] }, $x,
            $y );

        $x++;
        if ( $x == $width ) {
            $x = 0;
            $y++;
        }
    }

    return $image;
}

=head1 NAME

Image::TextMode::Reader::Bin - Reads Bin files

=head1 DESCRIPTION

Provides reading capabilities for the Bin format.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
