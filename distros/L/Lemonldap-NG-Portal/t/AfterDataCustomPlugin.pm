package t::AfterDataCustomPlugin;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_BADCREDENTIALS
);

extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant afterData => 'BadCredentials';

sub BadCredentials {
    my ( $self, $req ) = @_;
    my $uid = $self->conf->{customPluginsParams}->{uid};
    $self->logger->debug( "user=" . $req->user() );
    $self->logger->debug("Bad credentials required for: $uid");

    return $req->user() eq $uid ? PE_BADCREDENTIALS : PE_OK;
}

1;
