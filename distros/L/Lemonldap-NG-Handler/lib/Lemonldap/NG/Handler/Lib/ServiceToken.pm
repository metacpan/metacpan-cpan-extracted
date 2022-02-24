package Lemonldap::NG::Handler::Lib::ServiceToken;

use strict;

our $VERSION = '2.0.9';

sub fetchId {
    my ( $class, $req ) = @_;
    my $token = $req->{env}->{HTTP_X_LLNG_TOKEN};
    return $class->Lemonldap::NG::Handler::Main::fetchId($req)
      unless ( $token =~ /\w+/ );
    $class->logger->debug("Found token: $token");

    # Decrypt token
    my $s = $class->tsv->{cipher}->decrypt($token);

# Token format:
# time:_session_id:vhost1:vhost2:serviceHeader1=value1:serviceHeader2=value2,...
    my ( $t, $_session_id, @vhosts ) = split /:/, $s;
    $class->logger->debug("Found epoch: $t");
    $class->logger->debug("Found _session_id: $_session_id");

    # Looking for service headers
    my $vhost = $class->resolveAlias($req);
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
        $class->logger->debug(
            @vhosts ? 'No _session_id found' : 'No VH found' );
        return 0;
    }

    # Is vhost listed in token ?
    unless ( grep { $_ eq $vhost } @vhosts ) {
        $class->userLogger->error(
            "$vhost not authorized in token (" . join( ', ', @vhosts ) . ')' );
        return 0;
    }
    $class->logger->debug( 'Found VHosts: ' . join ', ', @vhosts );

    # Is token in good interval ?
    my $ttl =
         $class->localConfig->{vhostOptions}->{$vhost}->{vhostServiceTokenTTL}
      || $class->tsv->{serviceTokenTTL}->{$vhost};
    $ttl = $class->tsv->{handlerServiceTokenTTL} unless ( $ttl and $ttl > 0 );
    my $now = time;
    unless ( $t <= $now and $t > $now - $ttl ) {
        $class->userLogger->warn('Expired service token');
        $class->logger->debug("VH: $vhost with ServiceTokenTTL: $ttl");
        $class->logger->debug("TokenTime: $t / Time: $now");
        return 0;
    }

    # Send service headers to protected application if exist
    if (%serviceHeaders) {
        $class->logger->info("Append service header(s)...");
        $class->set_header_in( $req, %serviceHeaders );
    }

    return $_session_id;
}

1;
