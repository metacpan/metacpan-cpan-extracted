package Lemonldap::NG::Handler::Lib::ServiceToken;

use strict;

our $VERSION = '2.0.0';

sub fetchId {
    my ( $class, $req ) = @_;
    my $token = $req->{env}->{HTTP_X_LLNG_TOKEN};
    return $class->Lemonldap::NG::Handler::Main::fetchId($req) unless ($token);
    $class->logger->debug('Found token header');

    # Decrypt token
    my $s = $class->tsv->{cipher}->decrypt($token);

    # Token format:
    # time:_session_id:vhost1:vhost2,...
    my ( $t, $_session_id, @vhosts ) = split /:/, $s;

    # At least one vhost
    unless (@vhosts) {
        $class->userLogger->error('Bad service token');
        return 0;
    }

    # Is token in good interval ?
    unless ( $t <= time and $t > time - 30 ) {
        $class->userLogger->warn('Expired service token');
        return 0;
    }

    # Is vhost listed in token ?
    my $vh = $class->resolveAlias($req);
    unless ( grep { $_ eq $vh } @vhosts ) {
        $class->userLogger->error(
            "$vh not authorizated in token (" . join( ', ', @vhosts ) . ')' );
        return 0;
    }
    return $_session_id;
}

1;
