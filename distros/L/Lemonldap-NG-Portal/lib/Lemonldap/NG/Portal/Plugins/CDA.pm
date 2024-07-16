package Lemonldap::NG::Portal::Plugins::CDA;

use strict;
use Mouse;
use URI;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_APACHESESSIONERROR
  PE_ERROR
  PE_OK
  URIRE
);

our $VERSION = '2.0.14';

extends 'Lemonldap::NG::Common::Module';

# INTERFACE

use constant endAuth     => 'changeUrldc';
use constant forAuthUser => 'changeUrldc';

# RUNNING METHOD

sub _url_is_external {
    my ( $self, $req, $urldc ) = @_;

    my $portal = $req->portal;
    my $domain = $self->p->getCookieDomain($req);
    return $self->_cookie_can_be_seen( $portal, $domain, $urldc );
}

# This method determines if a cookie set by
# $portal for domain $domain can be received by URL $urldc
sub _cookie_can_be_seen {
    my ( $self, $portal, $domain, $urldc ) = @_;

    if ( $urldc =~ URIRE ) {
        my $host = $3;

        # Domain is set: cookie is sent to the domain itself, and all subdomains
        if ($domain) {
            my $domain_without_leading_dot = $domain =~ s/^\.//r;

            return if $host eq $domain_without_leading_dot;
            return $host !~ m@\Q$domain\E$@i;

        }

        # Domain is not set: cookie is only sent to the portal itself
        else {
            my $portal_host = URI->new($portal)->host;
            return $host ne $portal_host;
        }
    }
    return;
}

sub changeUrldc {
    my ( $self, $req ) = @_;
    my $urldc = $req->{urldc} || '';
    if (    $req->id
        and $self->_url_is_external( $req, $urldc )
        and $self->p->isTrustedUrl($urldc) )
    {
        my $ssl = $urldc =~ /^https/;
        $self->logger->debug('CDA request');

        # Create CDA session
        my $cdaInfos = { '_utime' => time };
        if ( $self->{conf}->{securedCookie} < 2 or $ssl ) {
            $cdaInfos->{cookie_value} = $req->id;
            $cdaInfos->{cookie_name}  = $self->{conf}->{cookieName};
        }
        else {
            if ( $req->{sessionInfo}->{_httpSession} ) {
                $cdaInfos->{cookie_value} =
                  $req->{sessionInfo}->{_httpSession};
                $cdaInfos->{cookie_name} = $self->{conf}->{cookieName} . "http";
            }
            else {
                $self->logger->error(
                        "Session does not contain _httpSession field. "
                      . "Portal must be accessed over HTTPS when using CDA with double cookie"
                );
                return PE_ERROR;
            }
        }

        my $cdaSession =
          $self->p->getApacheSession( undef, kind => "CDA", info => $cdaInfos );
        unless ($cdaSession) {
            $self->logger->error("Unable to create CDA session");
            return PE_APACHESESSIONERROR;
        }

        # We are about to redirect the user to the CDA application,
        # dismiss any previously stored redirections (#1650)
        delete $req->{pdata}->{_url};

        $req->{urldc} .=
            ( $urldc =~ /\?/ ? '&' : '?' )
          . $self->{conf}->{cookieName} . "cda="
          . $cdaSession->id;

        $self->logger->debug( "CDA redirection to " . $req->{urldc} );
    }
    return PE_OK;
}

1;
