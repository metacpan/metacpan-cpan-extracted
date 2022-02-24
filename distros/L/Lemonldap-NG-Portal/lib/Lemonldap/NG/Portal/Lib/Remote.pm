package Lemonldap::NG::Portal::Lib::Remote;

use strict;
use Mouse;
use MIME::Base64;
use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Portal::Main::Constants qw(
  URIRE
  PE_OK
  PE_ERROR
  PE_REDIRECT
);

our $VERSION = '2.0.14';

has cookieName => ( is => 'rw' );

# INITIALIZATION

sub init {
    my $self    = shift;
    my @missing = ();
    foreach (qw(remotePortal remoteGlobalStorage)) {
        push @missing, $_ unless ( defined( $self->conf->{$_} ) );
    }
    if (@missing) {
        $self->error( "Missing required parameters" . join( ', ', @missing ) );
        return 0;
    }

    unless ( $self->conf->{remotePortal} =~ URIRE ) {
        $self->error("Bad remotePortal URL");
        return 0;
    }

    eval "require " . $self->conf->{remoteGlobalStorage};
    if ($@) {
        $self->error($@);
        return 0;
    }
    $self->cookieName( $self->conf->{remoteCookieName}
          || $self->conf->{cookieName} );

    return 1;
}

# RUNNING METHODS

## @apmethod int checkRemoteId()
# check if a CDA mechanism has been instantiated and if session is available.
# Redirect user to remote portal else by calling goToPortal().
# @return Lemonldap::NG::Portal constant
sub checkRemoteId {
    my ( $self, $req ) = @_;
    my %h;

    if ( my $rId = $req->param( $self->cookieName ) ) {
        $req->mustRedirect(1);

        # Trying to recover session from global session storage
        my $remoteSession = Lemonldap::NG::Common::Session->new( {
                storageModule        => $self->conf->{remoteGlobalStorage},
                storageModuleOptions =>
                  $self->conf->{remoteGlobalStorageOptions},
                cacheModule        => $self->conf->{localSessionStorage},
                cacheModuleOptions => $self->conf->{localSessionStorageOptions},
                id                 => $rId,
                kind               => "SSO",
            }
        );
        if ( $remoteSession->error ) {
            $self->logger->error("Remote session error");
            $self->logger->error( $remoteSession->error );
            return PE_ERROR;
        }

        %{ $req->data->{rSessionInfo} } = %{ $remoteSession->data() };
        delete( $req->data->{rSessionInfo}->{'_password'} )
          unless $self->conf->{storePassword};
        return PE_OK;
    }

    return $self->goToPortal($req);
}

## @method protected void goToPortal()
# Redirect user to remote portal.
sub goToPortal {
    my ( $self, $req ) = @_;
    $req->urldc(
        $self->conf->{remotePortal} . '?url='
          . encode_base64(
            $self->conf->{portal}
              . ( $req->query_string ? '?' . $req->query_string : '' ),
            ''
          )
    );

    return PE_REDIRECT;
}

1;

