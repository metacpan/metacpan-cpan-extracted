# Plugin to enable "stay connected on this device" feature

package Lemonldap::NG::Portal::Plugins::StayConnected;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
);

our $VERSION = '2.18.0';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
);

# INTERFACE

use constant beforeAuth => 'check';
has rule => ( is => 'rw', default => sub { 0 } );

# INITIALIZATION
sub init {
    my ($self) = @_;

    # Parse activation rule
    $self->rule(
        $self->p->buildRule( $self->conf->{stayConnected}, 'stayConnected' ) );
    return 0 unless $self->rule;

    return 1;
}

# Check for:
sub check {
    my ( $self, $req ) = @_;

    if ( !$self->rule->( $req, $req->sessionInfo ) ) {
        $self->logger->debug("Stay Connected not allowed");
    }

    my $trustedBrowser = $self->p->_trustedBrowser;

    # Run TrustedBrowser challenge
    if ( $trustedBrowser->mustChallenge($req) ) {
        return $trustedBrowser->challenge( $req, '#');
    }
    elsif ( my $state = $trustedBrowser->getKnownBrowserState($req) ) {
        return $self->skipAuthentication( $req, $state );
    }
    return PE_OK;
}

# Remove authentication steps from the login flow
sub skipAuthentication {
    my ( $self, $req, $state ) = @_;
    my $uid = $state->{_trustedUser};
    $req->user($uid);
    $req->sessionInfo->{_stayConnectedSession} =
      $state->{_stayConnectedSession};
    $req->sessionInfo->{_trustedBrowser} = 1;
    my @steps =
      grep { ref $_ or $_ !~ /^(?:extractFormInfo|authenticate)$/ }
      @{ $req->steps };
    $req->steps( \@steps );
    $self->userLogger->notice("$uid connected by StayConnected cookie");
    return PE_OK;
}

1;
