package Image::TextMode::Writer;

use Moo;
use Carp 'croak';

=head1 NAME

Image::TextMode::Writer - A base class for file writers

=head1 DESCRIPTION

This module provides some of the basic functionality for all writer classes.

=head1 METHODS

=head2 new( %args )

Creates a new instance.

=head2 write( $image, $file, \%options )

Writes the contents of C<$image> to C<$file> via the subclass's C<_write()>
method.

=cut

sub write {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ( $self, $image, $fh, $options ) = @_;
    $options ||= {};
    $fh = _get_fh( $fh );

    $self->_write( $image, $fh, $options );

    $image->sauce->write( $fh ) if $image->has_sauce;
}

sub _get_fh {
    my ( $file ) = @_;

    my $fh = $file;
    if ( !ref $fh ) {
        undef $fh;
        open $fh, '>', $file    ## no critic (InputOutput::RequireBriefOpen)
            or croak "Unable to open '$file': $!";
    }

    binmode( $fh );
    return $fh;
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
