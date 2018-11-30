package Lemonldap::NG::Portal::Lib::REST;

use strict;
use Mouse;
use Lemonldap::NG::Common::UserAgent;
use JSON qw(from_json to_json);

our $VERSION = '2.0.0';

has ua => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
    }
);

sub restCall {
    my ( $self, $url, $content ) = @_;
    my $hreq = HTTP::Request->new( POST => $url );
    $hreq->header( 'Content-Type' => 'application/json' );
    $hreq->content( to_json($content) );
    my $resp = $self->ua->request($hreq);
    unless ( $resp->is_success ) {
        die $resp->status_line;
    }
    my $res = eval { from_json( $resp->content, { allow_nonref => 1 } ) };
    die "Bad REST response: $@" if ($@);
    return $res;
}

1;
