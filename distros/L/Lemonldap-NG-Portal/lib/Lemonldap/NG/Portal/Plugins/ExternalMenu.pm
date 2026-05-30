package Lemonldap::NG::Portal::Plugins::ExternalMenu;

use strict;
use Mouse;
use URI::Escape;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

our $VERSION = '2.23.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INTERFACE
use constant endAuth     => 'setExternalMenu';
use constant forAuthUser => 'setExternalMenu';

# INITIALIZATION
sub init {
    my ($self) = @_;

    my $url = $self->conf->{externalMenu};

    # Minimum URL format validation
    if ( $url and $url !~ m#^(?:\w+)://# ) {
        $self->logger->error('externalMenu must be a valid URL');
        return 0;
    }
    return 1;
}

# RUNNING METHOD
sub setExternalMenu {
    my ( $self, $req ) = @_;

    # Only set urldc if:
    # - Authentication succeeded (PE_OK)
    # - urldc is not already set
    unless ( $req->{urldc} ) {
        my $url = $self->conf->{externalMenu};
        $url =~ s/\$(\w+)/uri_escape($req->sessionInfo->{$1})/ge;
        $url =~ s/\$\{(\w+)\}/uri_escape($req->sessionInfo->{$1})/ge;
        $req->{urldc} = $url;
    }
    return PE_OK;
}

1;
