package HTML::Video::Embed::Site::FunnyOrDie;
use Moo;

with 'HTML::Video::Embed::Module';

our $VERSION = '0.016000';
$VERSION = eval $VERSION;

sub domain_reg {
    qr/funnyordie\.com/;
}

sub process {
    my ( $self, $embeder, $uri ) = @_;

    return undef if $embeder->secure;
    if ( my ( $vid ) = $uri->path =~ m|^/videos/(\w+)| ) {
        return qq|<iframe class="${ \$embeder->class }" src="http://www.funnyordie.com/embed/${vid}" frameborder="0" allowfullscreen="1"></iframe>|;
    }

    return undef;
}

1;
