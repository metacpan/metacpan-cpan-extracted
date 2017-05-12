package HTML::Video::Embed::Site::Collegehumor;
use Moo;

with 'HTML::Video::Embed::Module';

our $VERSION = '0.016000';
$VERSION = eval $VERSION;

sub domain_reg {
    qr/collegehumor\.com/
}

sub process {
    my ( $self, $embeder, $uri ) = @_;

    my $schema = $embeder->secure ? 'https' : 'http';
    if ( my ( $vid ) = $uri->path =~ m|^/video[:\/](\d+)| ) {
        return qq|<iframe class="${ \$embeder->class }" src="${schema}://www.collegehumor.com/e/${vid}" frameborder="0" allowfullscreen="1"></iframe>|;
    }

    return undef;
}

1;
