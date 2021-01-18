package Lemonldap::NG::Portal::Lib::REST;

use strict;
use Mouse;
use Lemonldap::NG::Common::UserAgent;
use JSON qw(from_json to_json);

our $VERSION = '2.0.6';

has ua => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
    }
);

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
