package Image::TextMode::Writer::ADF;

use Moo;

extends 'Image::TextMode::Writer';

# generates a 64 color palette
## no critic (BuiltinFunctions::ProhibitComplexMappings)
my $default_pal = [
    map {
        my @d = split( //s, sprintf( '%06b', $_ ) );
        {
            [   oct( "0b$d[ 3 ]$d[ 0 ]" ) * 63,
                oct( "0b$d[ 4 ]$d[ 1 ]" ) * 63,
                oct( "0b$d[ 5 ]$d[ 2 ]" ) * 63,
            ]
        }
        } 0 .. 63
];
## use critic

sub _write {
    my ( $self, $image, $fh, $options ) = @_;

    print $fh pack( 'C', $image->header->{ version } );

    print $fh _pack_pal( $image->palette );
    print $fh _pack_font( $image->font );

    for my $row ( @{ $image->pixeldata } ) {
        print $fh
            join( '',
            map { pack( 'aC', @{ $_ }{ qw( char attr ) } ) } @$row );
    }
}

sub _pack_font {
    my $font = shift;
    return pack( 'C*', map { @$_ } @{ $font->chars } );
}

sub _pack_pal {
    my $pal = shift;

    my @full_pal = @$default_pal;
    my @pal_map  = qw( 0 1 2 3 4 5 20 7 56 57 58 59 60 61 62 63 );

    # insert our colors into the appropriate slots in the 64-color array
    for ( 0 .. 15 ) {
        my @p = map { $_ >> 2 } @{ $pal->colors->[ $_ ] };
        $full_pal[ $pal_map[ $_ ] ] = \@p;
    }

    return pack( 'C*', map { @$_ } @full_pal );
}

=head1 NAME

Image::TextMode::Writer::ADF - Writes ADF files

=head1 DESCRIPTION

Provides writing capabilities for the ADF format.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
