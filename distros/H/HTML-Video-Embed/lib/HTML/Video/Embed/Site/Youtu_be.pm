package HTML::Video::Embed::Site::Youtu_be;
use Moo;

extends 'HTML::Video::Embed::Site::Youtube';

our $VERSION = '0.016000';
$VERSION = eval $VERSION;

sub domain_reg {
    qr/youtu\.be/;
}

sub process {
    my ( $self, $embeder, $uri ) = @_;

    my ( $vid ) = $uri->path =~ m|^/([a-zA-Z0-9-_]{11})|;
    return $self->_process( $embeder, $vid, $uri );
}

1;
