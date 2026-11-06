package HTTP::Body::OctetStream;
$HTTP::Body::OctetStream::VERSION = '1.25';
use strict;
use base 'HTTP::Body';
use bytes;

use File::Temp 0.14;

=head1 NAME

HTTP::Body::OctetStream - HTTP Body OctetStream Parser

=head1 SYNOPSIS

    use HTTP::Body::OctetStream;

=head1 DESCRIPTION

HTTP Body OctetStream Parser.  It stores the body unparsed in a temporary
file, for application/octet-stream, application/json and any content type
HTTP::Body has no other parser for.

=head1 METHODS

=over 4

=item spin

Writes the data that has arrived to a temporary file in
L<tmpdir|HTTP::Body/tmpdir>, which is the L<body|HTTP::Body/body>.  Once the
whole body is there, it seeks the file back to its start and sets the state to
done.  Croaks when the file can not be written.

=cut

sub spin {
    my $self = shift;

    unless ( $self->body ) {
        $self->body( File::Temp->new( DIR => $self->tmpdir ) );
    }

    if ( my $length = length( $self->{buffer} ) ) {
        $self->body->write( substr( $self->{buffer}, 0, $length, '' ), $length )
            or Carp::croak("Can't write to temporary file: $!");
    }

    if ( $self->length == $self->content_length ) {
        seek( $self->body, 0, 0 );
        $self->state('done');
    }
}

=back

=head1 SUPPORT

See L<HTTP::Body>

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
