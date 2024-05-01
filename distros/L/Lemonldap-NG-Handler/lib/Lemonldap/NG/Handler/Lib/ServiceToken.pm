package Lemonldap::NG::Handler::Lib::ServiceToken;

use strict;

our $VERSION = '2.19.0';

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
            $class->logger->warn("Found a non valid VHost: $_");
            0;
        }
    } @vhosts;

    # $_session_id and at least one vhost or RegExp
    unless ( $_session_id and ( @vhosts or @vhostRegexp ) ) {
        $class->auditLog(
            $req,
            message => 'Bad service token',
            code    => "INVALID_SERVICE_TOKEN",
        );
        $class->logger->debug(
            $_session_id ? 'No VH or RegExp found' : 'No _session_id found' );
        return 0;
    }

    # Is vhost listed in token ?
    if ( grep { $_ eq $vhost } @vhosts ) {
        $class->logger->debug( "$vhost found in VHosts list: " . join ', ',
            @vhosts );
    }
    elsif ( grep { $vhost =~ $_ } @vhostRegexp ) {
        $class->logger->debug( "$vhost matches a VHost regexp: " . join ', ',
            @vhostRegexp );
    }
    else {
        $class->auditLog(
            $req,
            message => (
                "$vhost not allowed in token scope ("
                  . join( ', ', ( @vhostRegexp, @vhosts ) ) . ')'
            ),
            code        => "INVALID_SERVICE_TOKEN_SCOPE",
            vhostRegexp => \@vhostRegexp,
            vhosts      => \@vhosts,
        );
        return 0;
    }

    # Is token in good interval ?
    my $ttl =
      ( $class->tsv->{serviceTokenTTL}->{$vhost} > 0 )
      ? $class->tsv->{serviceTokenTTL}->{$vhost}
      : $class->tsv->{handlerServiceTokenTTL};
    my $now = time;
    unless ( $t <= $now and $t > $now - $ttl ) {
        $class->auditLog(
            $req,
            message => 'Expired service token',
            code    => "EXPIRED_SERVICE_TOKEN",
        );
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
