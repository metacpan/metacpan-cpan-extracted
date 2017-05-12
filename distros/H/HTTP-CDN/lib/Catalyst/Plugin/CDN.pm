package Catalyst::Plugin::CDN;
{
  $Catalyst::Plugin::CDN::VERSION = '0.8';
}

use Moose::Role;
use HTTP::CDN;
use Path::Class;
use HTTP::Date;

=head3 EXPIRES

Approximately 10 years

=cut

use constant EXPIRES => 315_576_000;

around dispatch => sub {
    my $orig = shift;
    my ($c) = @_;

    my $cdn = $c->config->{'Plugin::CDN'}{cdn};

    # TODO - this path match should be using the configurable 'base' below
    if ( $c->req->path =~ m{ \A cdn/ (.*) \z }xms ) {
        my ($uri, $hash) = $cdn->unhash_uri($1);

        my $info = eval { $cdn->fileinfo($uri) };

        unless ( $info and $info->{hash} eq $hash ) {
            $c->res->status( 404 );
            $c->res->content_type( 'text/html' );
            return;
        }

        $c->res->status( 200 );
        $c->res->content_type( $info->{mime}->type );
        $c->res->headers->header('Last-Modified' => HTTP::Date::time2str($info->{stat}->mtime));
        $c->res->headers->header('Expires' => HTTP::Date::time2str(time + EXPIRES));
        $c->res->headers->header('Cache-Control' => 'max-age=' . EXPIRES . ', public');
        $c->res->body($cdn->filedata($uri));

        # We do this at the very end incase something goes horribly wrong beforehand
        if ( $c->log->can('abort') ) {
            $c->log->abort(1);
        }

        return;
    }
    else {
        return $orig->(@_);
    }
};

before setup_finalize => sub {
    my ($c) = @_;

    my $plugin_config = $c->config->{'Plugin::CDN'} // {};

    my $root = $plugin_config->{root} //= $c->path_to('cdn');
    my $base = $plugin_config->{base} //= '/cdn/';
    my $plugins = $plugin_config->{plugins};
    unless ( UNIVERSAL::isa($plugin_config->{plugins}, 'ARRAY') ) {
        $plugins = $plugin_config->{plugins} = undef;
    }

    $c->config->{'Plugin::CDN'}{cdn} = HTTP::CDN->new(
        root    => $root,
        base    => $base,
        ( $plugins ? (plugins => $plugins) : () ),
    );
};

=head2 cdn

This is how you link to CDN content from your Catalyst application.

  $c->cdn('style.css')

Will generate a nice unique URL for your project's cdn/style.css file based on
a hash of the file content, this URI will automatically be served up correctly.

=cut

sub cdn {
    my ($c, $uri) = @_;

    my $cdn = $c->config->{'Plugin::CDN'}{cdn};

    return $cdn->resolve($uri);
}

1;
__END__
