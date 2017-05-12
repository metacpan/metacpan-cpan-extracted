package HTML::Video::Embed::Site::EbaumsWorld;
use Moo;

with 'HTML::Video::Embed::Module';

our $VERSION = '0.016000';
$VERSION = eval $VERSION;

sub domain_reg {
    qr/ebaumsworld\.com/;
}

sub process {
    my ( $self, $embeder, $uri ) = @_;

    return undef if $embeder->secure;
    if ( my ( $vid ) = $uri->path =~ m|^/video/watch/(\d+)| ) {
        return qq|<iframe class="${ \$embeder->class }" src="http://www.ebaumsworld.com/media/embed/${vid}" frameborder="0" allowfullscreen="1"></iframe>|;
    }

    return undef;
}

1;
