package Lemonldap::NG::Handler::Lib::ServiceToken;

use strict;
use Data::Dumper;

our $VERSION = '2.0.5';

sub fetchId {
    my ( $class, $req ) = @_;
    my $token = $req->{env}->{HTTP_X_LLNG_TOKEN};
    return $class->Lemonldap::NG::Handler::Main::fetchId($req) unless ($token);
    $class->logger->debug('Found token header');

    # Decrypt token
    my $s = $class->tsv->{cipher}->decrypt($token);

# Token format:
# time:_session_id:vhost1:vhost2:serviceHeader1=value1:serviceHeader2=value2,...
    my ( $t, $_session_id, @vhosts ) = split /:/, $s;

    # Looking for service headers
    my $vh = $class->resolveAlias($req);
    my %serviceHeaders;
    @vhosts = grep {
        if (/^([\w\-]+)=(.+)$/) {
            $serviceHeaders{$1} = $2;
            $class->logger->debug("Found service header: $1 => $2");
            0;
        }
        else { 1 }
    } @vhosts;

    # $_session_id and at least one vhost
    unless ( @vhosts and $_session_id ) {
        $class->userLogger->error('Bad service token');
        return 0;
    }

    # Is vhost listed in token ?
    unless ( grep { $_ eq $vh } @vhosts ) {
        $class->userLogger->error(
            "$vh not authorized in token (" . join( ', ', @vhosts ) . ')' );
        return 0;
    }

    # Is token in good interval ?
    my $localConfig = $class->localConfig;
    my $ttl =
        $localConfig->{vhostOptions}->{$vh}->{vhostServiceTokenTTL} <= 0
      ? $class->tsv->{handlerServiceTokenTTL}
      : $localConfig->{vhostOptions}->{$vh}->{vhostServiceTokenTTL};
    unless ( $t <= time and $t > time - $ttl ) {
        $class->userLogger->warn('Expired service token');
        return 0;
    }

    if (%serviceHeaders) {
        $class->logger->debug("Append service header(s)...");
        $class->set_header_out( $req, %serviceHeaders );
    }

    return $_session_id;
}

1;
