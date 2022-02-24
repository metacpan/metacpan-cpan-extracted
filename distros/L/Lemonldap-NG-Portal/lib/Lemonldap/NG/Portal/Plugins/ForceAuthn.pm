package Lemonldap::NG::Portal::Plugins::ForceAuthn;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_MUSTAUTHN
);

our $VERSION = '2.0.14';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INITIALIZATION

use constant forAuthUser => 'run';

# RUNNING METHOD

sub run {
    my ( $self, $req ) = @_;
    if (    $req->env->{HTTP_HOST}
        and $self->conf->{portal} =~ /\Q$req->{env}->{HTTP_HOST}/ )
    {
        my $delta = time - $req->{sessionInfo}->{_utime};
        $self->logger->debug( "Delta with last Authn -> " . $delta );

        return $delta <= $self->conf->{portalForceAuthnInterval}
          ? PE_OK
          : PE_MUSTAUTHN;
    }
}

1;
