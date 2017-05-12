package HTML::Video::Embed::Site::MetaCafe;
use Moo;

with 'HTML::Video::Embed::Module';

our $VERSION = '0.016000';
$VERSION = eval $VERSION;

sub domain_reg {
    qr/metacafe\.com/;
}

sub process{
    my ( $self, $embeder, $uri ) = @_;

    return undef if $embeder->secure;
    if ( my ( $vid ) = $uri->path =~ m|^/watch/(\d+)/| ) {
        return qq|<iframe src="http://www.metacafe.com/embed/${vid}/" class="${ \$embeder->class }" frameborder="0" allowfullscreen="1"></iframe>|;
    }

    return undef;
}

1;
