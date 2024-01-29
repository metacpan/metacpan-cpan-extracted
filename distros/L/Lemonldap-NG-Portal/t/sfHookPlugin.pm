package t::sfHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR);

use constant hook => { sfBeforeVerify => 'ipHasChanged', };

sub ipHasChanged {
    my ( $self, $req, $sfa, $session ) = @_;
    my $prefix = $sfa->prefix;

    if ( $req->address ne $session->{ipAddr} ) {
        $self->logger->error("Error when validating $prefix: IP has changed");
        return 998;
    }

    return PE_OK;
}

1;
