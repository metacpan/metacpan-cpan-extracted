package Lemonldap::NG::Portal::Lib::OIDCPlugin;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Issuer::OpenIDConnect;

extends 'Lemonldap::NG::Portal::Main::Plugin';

our $VERSION = '2.23.0';

has oidc => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]
          ->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::OpenIDConnect'};
    }
);

has path => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->oidc->path }
);

sub init {
    my ($self) = @_;
    unless ( $self->conf->{issuerDBOpenIDConnectActivation} ) {
        $self->logger->error(
            'This plugin can be used only if OIDC server is enabled');
        return 0;
    }
    1;
}

1;
