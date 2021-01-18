package Lemonldap::NG::Manager::Plugin;

use strict;
use Mouse;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Common::Conf::Constants;
use URI::URL;

our $VERSION = '2.0.10';

extends 'Lemonldap::NG::Common::Module';

has _confAcc => (
    is      => 'rw',
    lazy    => 1,
    default => sub { return $_[0]->p->{_confAcc} },
);

has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
    }
);

sub sendError {
    my $self = shift;
    return $self->p->sendError(@_);
}

sub sendJSONresponse {
    my $self = shift;
    return $self->p->sendJSONresponse(@_);
}

sub addRoute {
    my ( $self, $word, $subName, $methods, $transform ) = @_;
    $transform //= sub {
        my ($sub) = @_;
        if ( ref $sub ) {
            return sub {
                shift;
                return $sub->( $self, @_ );
            }
        }
        else {
            return sub {
                shift;
                return $self->$sub(@_);
            }
        }
    };
    $self->p->addRoute( $word, $subName, $methods, $transform );
    return $self;
}

sub loadTemplate {
    my $self = shift;
    return $self->p->loadTemplate(@_);
}

## @method private applyConf()
# Try to inform other servers declared in `reloadUrls` that a new
# configuration is available.
#
#@return reload status as boolean
sub applyConf {
    my ( $self, $newConf ) = @_;
    my $status;

    # 1 Apply conf locally
    $self->p->api->checkConf();

    # Get apply section values
    my %reloadUrls =
      %{ $self->confAcc->getLocalConf( APPLYSECTION, undef, 0 ) };
    if ( !%reloadUrls && $newConf->{reloadUrls} ) {
        %reloadUrls = %{ $newConf->{reloadUrls} };
    }
    return {} unless (%reloadUrls);

    $self->ua->timeout( $newConf->{reloadTimeout} );

    # Parse apply values
    while ( my ( $host, $request ) = each %reloadUrls ) {
        my $r = HTTP::Request->new( 'GET', "http://$host$request" );
        $self->logger->debug("Sending reload request to $host");
        if ( $request =~ /^https?:\/\/[^\/]+.*$/ ) {
            my $url       = URI::URL->new($request);
            my $targetUrl = $url->scheme . "://" . $host;
            $targetUrl .= ":" . $url->port if defined( $url->port );
            $targetUrl .= $url->full_path;
            $r =
              HTTP::Request->new( 'GET', $targetUrl,
                HTTP::Headers->new( Host => $url->host ) );
            if ( defined $url->userinfo
                && $url->userinfo =~ /^([^:]+):(.*)$/ )
            {
                $r->authorization_basic( $1, $2 );
            }
        }

        my $response = $self->ua->request($r);
        if ( $response->code != 200 ) {
            $status->{$host} =
              "Error " . $response->code . " (" . $response->message . ")";
            $self->logger->error( "Apply configuration for $host: error "
                  . $response->code . " ("
                  . $response->message
                  . ")" );
        }
        else {
            $status->{$host} = "OK";
            $self->logger->notice("Apply configuration for $host: ok");
        }
    }

    return $status;
}

1;
