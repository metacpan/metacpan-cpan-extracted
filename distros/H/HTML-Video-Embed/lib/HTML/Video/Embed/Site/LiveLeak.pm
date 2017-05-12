package HTML::Video::Embed::Site::LiveLeak;
use Moo;

with 'HTML::Video::Embed::Module';

our $VERSION = '0.016000';
$VERSION = eval $VERSION;

sub domain_reg {
    return qr/liveleak\.com/;
}

sub process {
    my ( $self, $embeder, $uri ) = @_;

    return undef if $embeder->secure;

    my $query_param = 'i';

    my $vid = $uri->query_param('i');
    if ( !$vid ){
        $vid = $uri->query_param('f');
        $query_param = 'f';
    }
    $vid ||= '';

    if ( $vid =~ m/^(?:\w{3}_\w{10}|\w{12})$/ ) {
        return qq|<iframe class="${ \$embeder->class }" src="http://www.liveleak.com/ll_embed?${query_param}=${vid}" frameborder="0" allowfullscreen="1"></iframe>|;
    }

    return undef;
}

1;
