package HTML::Video::Embed::Site::Youtube;
use Moo;

with 'HTML::Video::Embed::Module';

our $VERSION = '0.016000';
$VERSION = eval $VERSION;

sub domain_reg {
    return qr/youtube\.com/;
}

sub process {
    my ( $self, $embeder, $uri ) = @_;

    my ( $vid ) = ( $uri->query_param('v') || '' ) =~ m|^([a-zA-Z0-9-_]{11})$|;

    return $self->_process( $embeder, $vid, $uri );
}

sub _process {
    my ( $self, $embeder, $vid, $uri ) = @_;

    if ( $vid ){
        my $timecode = $uri->query_param('t') || $uri->fragment || '';
        $vid .= '?rel=0&html5=1';
        if ( 
            defined( $timecode )
            && ( my @time = $timecode =~ m/(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)/ )
        ){
            my $start = 0;
            if ( $time[0] ){
            #hours
                $start += 3600 * $time[0];
            }
            if ( $time[1] ){
            #mins
                $start += 60 * $time[1];
            }
            if ( $time[2] ){
            #seconds
                $start += $time[2];
            }
            if ( $start ){
                $vid .= "&start=${start}";
            }
        }

        my $schema = $embeder->secure ? 'https' : 'http';
        return qq|<iframe class="${ \$embeder->class }" src="${schema}://www.youtube-nocookie.com/embed/${vid}" frameborder="0" allowfullscreen="1"></iframe>|;
    }

    return undef;
}

1;
