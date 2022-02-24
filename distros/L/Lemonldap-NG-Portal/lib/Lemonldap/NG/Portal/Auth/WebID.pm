package Lemonldap::NG::Portal::Auth::WebID;

use strict;
use Mouse;
use Regexp::Assemble;
use Web::ID;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_BADPARTNER
  PE_BADCERTIFICATE
  PE_BADCREDENTIALS
  PE_CERTIFICATEREQUIRED

);

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Main::Auth';

# PROPERTIES

has SSLField => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return ( $_[0]->{conf}->{SSLVar} || 'SSL_CLIENT_S_DN_Email' );
    }
);

has reWebIDWhitelist => ( is => 'rw' );

# INITIALIZATION

sub init {
    my ($self) = @_;
    my @hosts  = split /\s+/, $self->{conf}->{webIDWhitelist};
    unless (@hosts) {
        $self->error(
'WebID white list is empty. Set it in manager, use * to accept all FOAF providers'
        );
        return 0;
    }
    my $re = Regexp::Assemble->new();
    foreach my $h (@hosts) {
        $self->logger->debug("Add $h in WebID whitelist");
        $h = quotemeta($h);
        $h =~ s/\\\*/\.\*\?/g;
        $re->add($h);
    }
    my $reString = '^https?://' . $re->as_string . '(?:/.*|)$';
    $self->reWebIDWhitelist(qr($reString));
    return 1;
}

# Read username in SSL environment variables, or return an error
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my ( $self, $req ) = @_;

    # 1. Verify SSL exchange
    unless ( $req->{SSL_CLIENT_S_DN} ) {
        $self->userLogger->warn( 'No certificate found for ' . $req->address );
        return PE_CERTIFICATEREQUIRED;
    }

    # 2. Verify that certificate is WebID compliant
    #    NB: WebID URI is used as user field
    eval {
        $req->data->{_webid} =
          Web::ID->new( certificate => $req->{SSL_CLIENT_CERT} );
        $req->user( $req->data->{_webid}->uri->as_string );
    };
    return PE_BADCERTIFICATE if ( $@ or not( $req->user ) );

    # 3. Verify that FOAF host is in white list
    return PE_BADPARTNER unless ( $req->user =~ $self->reWebIDWhitelist );

    # 4. Verify FOAF document
    return PE_BADCREDENTIALS unless ( $req->data->{_webid}->valid() );
    $req->data->{_webIdAuthDone}++;

    # 5. OK, access granted
    return PE_OK;
}

sub authenticate {
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{authenticationLevel} = $self->conf->{webIDAuthnLevel};
    return PE_OK;
}

sub getDisplayType {
    return "logo";
}

1;
