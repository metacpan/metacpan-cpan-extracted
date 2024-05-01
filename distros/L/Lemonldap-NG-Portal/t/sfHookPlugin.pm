package t::sfHookPlugin;

use Mouse;
extends 'Lemonldap::NG::Portal::Main::Plugin';

use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR);

use constant hook => {
    sfBeforeVerify => 'ipHasChanged',
    sfBeforeRetry  => 'allowedToRetry',
};

sub ipHasChanged {
    my ( $self, $req, $sfa, $session ) = @_;
    my $prefix = $sfa->prefix;

    if ( $req->address ne $session->{ipAddr} ) {
        $self->logger->error("Error when validating $prefix: IP has changed");
        return 998;
    }

    return PE_OK;
}

sub allowedToRetry {
    my ( $self, $req, $module ) = @_;
    my $prefix = $module->prefix;

    my $uid = $req->sessionInfo->{uid};
    if ( $uid eq "msmith" ) {
        $self->logger->error("User $uid not allowed to retry $prefix");
        return 999;
    }
    return PE_OK;
}

1;
