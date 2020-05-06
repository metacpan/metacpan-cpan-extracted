package Lemonldap::NG::Common::Conf::Backends::REST;

use strict;
use Lemonldap::NG::Common::UserAgent;
use JSON qw(from_json to_json);

our $VERSION = '2.0.0';

#parameter baseUrl, user, password, realm, lwpOpts

BEGIN {
    *Lemonldap::NG::Common::Conf::getJson = \&getJson;
    *Lemonldap::NG::Common::Conf::ua      = \&ua;
    *Lemonldap::NG::Common::Conf::base    = \&base;
}

sub prereq {
    my $self = shift;
    unless ( $self->{baseUrl} ) {
        $Lemonldap::NG::Common::Conf::msg .=
          "url parameter is required in REST configuration type \n";
        return 0;
    }
    if ( $self->{user} and not $self->{realm} ) {
        $Lemonldap::NG::Common::Conf::msg .=
          "realm is required when user/password are set\n";
        return 0;
    }
    1;
}

sub ua {
    my ($self) = @_;
    return $self->{ua} if ( $self->{ua} );
    my $ua = Lemonldap::NG::Common::UserAgent->new();
    if ( $self->{user} ) {
        my $url  = $self->{baseUrl};
        my $port = ( $url =~ /^https/ ? 443 : 80 );
        $url =~ s#https?://([^/]*).*$#$1#;
        $port = $1 if ( $url =~ s/:(\d+)$// );
        $ua->credentials( "$url:$port", $self->{realm},
            $self->{user}, $self->{password} );
    }
    return $self->{ua} = $ua;
}

sub getJson {
    my $self = shift;
    my $url  = shift;
    my $resp = $self->ua->get( $self->base . $url, @_ );
    if ( $resp->is_success ) {
        my $res;
        eval { $res = from_json( $resp->content, { allow_nonref => 1 } ) };
        if ($@) {
            $Lemonldap::NG::Common::Conf::msg .= "Request failed: $@\n";
            return undef;
        }
        return $res;
    }
    else {
        $Lemonldap::NG::Common::Conf::msg .=
          "Request failed: status code " . $resp->status_line;
        return undef;
    }
}

sub base {
    my ($self) = @_;
    $self->{baseUrl} =~ s#/*$#/#;
    return $self->{baseUrl};
}

sub available {

    # TODO
    print STDERR 'Not implemented for now';
    return undef;
}

sub lastCfg {
    my $self = shift;
    my $res  = $self->getJson('latest') or return;
    return $res->{cfgNum};
}

# lock and unlock must not be requested by the SOAP client, since
# they will be done by the SOAP server when storing the config
sub lock {
    return 1;
}

sub unlock {
    return 1;
}

sub isLocked {
    return 1;
}

sub store {

    # TODO
    print STDERR 'Not implemented for now';
    return undef;
    my ( $self, $conf ) = @_;
    my $req = HTTP::Request->new( POST => $self->base );
    $req->content( to_json($conf) );
    $req->header( 'Content-Type' => 'application/json' );
    my $resp = $self->ua->request($req);

    if ( $resp->is_success ) {
        my $res;
        eval { $res = from_json( $resp->content, { allow_nonref => 1 } ) };
        if ($@) {
            $Lemonldap::NG::Common::Conf::msg .= "Unknown error: $@";
            return undef;
        }
        return $res->{cfgNum};
    }
    $Lemonldap::NG::Common::Conf::msg .= 'Unknown error: ' . $resp->status_line;
    return undef;
    return $self->_soapCall( 'store', @_ );
}

sub load {
    my ( $self, $cfgNum ) = @_;
    my $res = $self->getJson("$cfgNum?full=1") or return;
    return $res;
}

1;
