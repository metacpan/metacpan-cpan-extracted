package Lemonldap::NG::Handler::Lib::ServiceToken;

use strict;

our $VERSION = '2.0.16';

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
    my ( %serviceHeaders, @vhostRegexp );
    @vhosts = grep {
        if (/^([\w\-]+)=(.+)$/) {
            $serviceHeaders{$1} = $2;
            $class->logger->debug("Found service header: $1 => $2");
            0;
        }
        elsif (m#^/(.+)?/$#) {
            push @vhostRegexp, qr/$1/;
            $class->logger->debug("Found VHost regexp: $1");
            0;
        }
        elsif (/^[\w.*%-]+$/) {
            $class->logger->debug("Found VHost: $_");
            1;
        }
        else {
            $class->logger->debug("Found a non valid VHost: $_");
            0;
        }
    } @vhosts;

    # $_session_id and at least one vhost
    unless ( @vhosts and $_session_id ) {
        $class->userLogger->error('Bad service token');
        $class->logger->debug(
            @vhosts ? 'No _session_id found' : 'No VH found' );
        return 0;
    }

    # Is vhost listed in token ?
    if ( grep { $_ eq $vhost } @vhosts ) {
        $class->logger->debug( "$vhost found in VHosts list: " . join ', ', @vhosts );
    }
    elsif ( grep { $vhost =~ $_ } @vhostRegexp ) {
        $class->logger->debug( "$vhost matches a VHost regexp: " . join ', ',
            @vhostRegexp );
    }
    else {
        $class->userLogger->error( "$vhost not allowed in token scope ("
              . join( ', ', ( @vhostRegexp, @vhosts, ) )
              . ')' );
        return 0;
    }

    # Is token in good interval ?
    my $ttl = $class->tsv->{serviceTokenTTL}->{$vhost}
      || $class->tsv->{handlerServiceTokenTTL};
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
