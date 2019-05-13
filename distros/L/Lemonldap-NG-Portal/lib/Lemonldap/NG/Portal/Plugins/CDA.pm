package Lemonldap::NG::Portal::Plugins::CDA;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_APACHESESSIONERROR
  PE_OK
);

our $VERSION = '2.0.3';

extends 'Lemonldap::NG::Common::Module';

# INTERFACE

use constant endAuth     => 'changeUrldc';
use constant forAuthUser => 'changeUrldc';

sub init { 1 }

# RUNNING METHOD

sub changeUrldc {
    my ( $self, $req ) = @_;
    my $urldc = $req->{urldc} || '';
    if (    $req->id
        and $urldc !~ m#^https?://[^/]*$self->{conf}->{domain}(:\d+)?/#oi
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
            $cdaInfos->{cookie_value} =
              $req->{sessionInfo}->{_httpSession};
            $cdaInfos->{cookie_name} = $self->{conf}->{cookieName} . "http";
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
    PE_OK;
}

1;
