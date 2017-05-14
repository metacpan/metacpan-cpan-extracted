## @file
# Proxy authentication and userDB base.

## @class
# Proxy authentication and userDB base class.
package Lemonldap::NG::Portal::_Proxy;

use strict;
use Lemonldap::NG::Portal::Simple;
use MIME::Base64;
use SOAP::Lite;

our $VERSION = '1.9.1';
our $initDone;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($initDone);
    };
}

## @apmethod int proxyInit()
# Checks if remote portal parameters are set.
# @return Lemonldap::NG::Portal constant
sub proxyInit {
    my $self = shift;
    $self->{soapSessionService} ||=
      $self->{soapAuthService} . 'index.pl/sessions';
    $self->{soapSessionService} =~ s/\.plindex.pl/\.pl/;
    $self->{remoteCookieName} ||= $self->{cookieName};

    return PE_OK if ($initDone);

    my @missing = ();
    foreach (qw(soapAuthService)) {
        push @missing, $_ unless ( defined( $self->{$_} ) );
    }
    $self->abort( "Missing parameters",
        "Required parameters: " . join( ', ', @missing ) )
      if (@missing);
    $initDone = 1;
    PE_OK;
}

## @apmethod int proxyQuery()
# Queries the remote portal to authenticate users using given credentials
sub proxyQuery {
    my $self = shift;
    return PE_OK if ( $self->{_proxyQueryDone} );
    my $soap =
      SOAP::Lite->proxy( $self->{soapAuthService} )
      ->uri('urn:Lemonldap::NG::Common::CGI::SOAPService');
    my $r = $soap->getCookies( $self->{user}, $self->{password} );
    if ( $r->fault ) {
        $self->abort( "Unable to query authentication service",
            $r->fault->{faultstring} );
    }
    my $res = $r->result();

    # If authentication failed, display error
    if ( $res->{error} ) {
        $self->_sub( 'userError',
            "Authentication failed for $self->{user} "
              . $soap->error( $res->{error} )->result() );
        return PE_BADCREDENTIALS;
    }
    $self->{_remoteId} = $res->{cookies}->{ $self->{remoteCookieName} }
      or $self->abort("No cookie named $self->{remoteCookieName}");
    $self->{_proxyQueryDone}++;
    PE_OK;
}

## @apmethod int setSessionInfo()
# Queries the remote portal to get users attributes and
# store them in local session
sub setSessionInfo {
    my $self = shift;
    return PE_OK if ( $self->{_setSessionInfoDone} );
    my $soap =
      SOAP::Lite->proxy( $self->{soapSessionService} )
      ->uri('urn:Lemonldap::NG::Common::CGI::SOAPService');
    my $r = $soap->getAttributes( $self->{_remoteId} );
    if ( $r->fault ) {
        $self->abort( "Unable to query authentication service",
            $r->fault->{faultstring} );
    }
    my $res = $r->result();
    if ( $res->{error} ) {
        $self->_sub( 'userError',
            "Unable to get attributes for $self->{user} " );
        return PE_ERROR;
    }
    foreach ( keys %{ $res->{attributes} } ) {
        $self->{sessionInfo}->{$_} ||= $res->{attributes}->{$_}
          unless (/^_/);
    }
    $self->{_setSessionInfoDone}++;
    PE_OK;
}

1;

