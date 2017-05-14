## @file
# Remote authentication and userDB base.

## @class
# Remote authentication and userDB base class.
package Lemonldap::NG::Portal::_Remote;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Common::Session;
use MIME::Base64;

our $VERSION = '1.9.1';
our $initDone;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($initDone);
    };
}

## @apmethod int init()
# Checks if remote portal parameters are set.
# @return Lemonldap::NG::Portal constant
sub init {
    my $self = shift;
    return PE_OK if ($initDone);

    my @missing = ();
    foreach (qw(remotePortal remoteGlobalStorage)) {
        push @missing, $_ unless ( defined( $self->{$_} ) );
    }
    $self->abort( "Missing parameters",
        "Required parameters: " . join( ', ', @missing ) )
      if (@missing);
    eval "require " . $self->{remoteGlobalStorage};
    $self->abort( "Configuration error",
        "Module " . $self->{remoteGlobalStorage} . " not found in \@INC" )
      if ($@);
    $self->{remoteCookieName} ||= $self->{cookieName};

    $initDone = 1;
    PE_OK;
}

## @apmethod int checkRemoteId()
# check if a CDA mechanism has been instanciated and if session is available.
# Redirect the user to the remote portal else by calling goToPortal().
# @return Lemonldap::NG::Portal constant
sub checkRemoteId {
    my $self = shift;
    my %h;

    if ( my $rId = $self->param( $self->{remoteCookieName} ) ) {
        $self->{mustRedirect} = 1;

        # Trying to recover session from global session storage

        my $remoteSession = Lemonldap::NG::Common::Session->new(
            {
                storageModule        => $self->{remoteGlobalStorage},
                storageModuleOptions => $self->{remoteGlobalStorageOptions},
                cacheModule          => $self->{localSessionStorage},
                cacheModuleOptions   => $self->{localSessionStorageOptions},
                id                   => $rId,
                kind                 => "REMOTE",
            }
        );

        if ( $remoteSession->error ) {
            $self->lmLog( "Remote session error", 'error' );
            $self->lmLog( $remoteSession->error,  'error' );
            return PE_ERROR;
        }

        %{ $self->{rSessionInfo} } = %{ $remoteSession->data() };
        delete( $self->{rSessionInfo}->{'_password'} )
          unless ( $self->{storePassword} );
        return PE_OK;
    }
    return $self->_sub('goToPortal');
}

## @method protected void goToPortal()
# Redirect the user to the remote portal.
sub goToPortal {
    my $self = shift;
    print $self->redirect(
        $self->{remotePortal} . "?url="
          . encode_base64(
            $self->{portal}
              . ( $ENV{QUERY_STRING} ? "?$ENV{QUERY_STRING}" : '' ),
            ''
          )
    );
    exit;
}

1;

