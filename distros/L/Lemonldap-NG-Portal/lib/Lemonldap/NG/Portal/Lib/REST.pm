package Lemonldap::NG::Portal::Lib::REST;

use strict;
use Mouse;
use Lemonldap::NG::Common::UserAgent;
use JSON qw(from_json to_json);

our $VERSION = '2.23.0';

has ua => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
    }
);

has namedCalls => ( is => 'rw', default => sub { {} } );

sub initNamedCallFromConf {
    my ( $self, $name_conf, $name_internal, $mandatory ) = @_;

    my $name_internal_url   = "${name_internal}Url";
    my $name_internal_attrs = "${name_internal}Attrs";

    if ( !$self->conf->{"${name_conf}Url"} ) {
        $self->logger->debug("${name_conf}Url is missing");
        return 0;
    }
    $self->namedCalls->{$name_internal}->{url} =
      $self->conf->{"${name_conf}Url"};

    while ( my ( $k, $rule_or_attr ) =
        each %{ $self->conf->{"${name_conf}Args"} } )
    {
        my $rule;

        # Tolerate using the name of an attribute instead of an actual
        # perl expression for backward compatibility
        if ( $rule_or_attr =~ /^\w+$/ ) {
            $rule = $self->p->buildRule( "\$$rule_or_attr",
                "REST $name_internal_attrs custom argument $k" );
        }
        else {
            $rule = $self->p->buildRule( $rule_or_attr,
                "REST $name_internal_attrs custom argument $k" );
        }

        next unless $rule;
        $self->logger->debug("$name_conf: push verify attribute $k");
        $self->namedCalls->{$name_internal}->{attrs}->{$k} = $rule;
    }

    return 1;
}

sub restNamedCall {
    my ( $self, $req, $name, $initial_content, $session_info ) = @_;
    my $url_accessor  = "${name}Url";
    my $attr_accessor = "${name}Attrs";
    my $url           = $self->namedCalls->{$name}->{url};

    die "Could not find URL for $name REST call" unless $url;
    my $content = { %{ $initial_content || {} } };
    while ( my ( $json_key, $rule ) =
        each %{ $self->namedCalls->{$name}->{attrs} } )
    {
        my $value = $rule->( $req, $session_info );
        if ( defined $value ) {
            $content->{$json_key} = $value;
        }
    }

    return $self->restCall( $url, $content );
}

sub restCall {
    my ( $self, $url, $content ) = @_;
    $self->logger->debug("REST: trying to call $url with:");
    eval {
        foreach ( keys %$content ) {
            $self->logger->debug(
                " $_: " . ( /password/ ? '****' : $content->{$_} ) );
        }
    };
    my $hreq = HTTP::Request->new( POST => $url );
    $hreq->header( 'Content-Type' => 'application/json' );
    $hreq->content( to_json($content) );
    my $resp = $self->ua->request($hreq);
    die $resp->status_line unless $resp->is_success;

    my $res = eval { from_json( $resp->content ) };
    die "Bad REST response: $@" if ($@);
    if ( ref($res) ne "HASH" ) {
        die "Bad REST response: expecting a JSON HASH, got " . ref($res);
    }
    return $res;
}

1;
