package Lemonldap::NG::Handler::Lib::DevOps;

use strict;
use Lemonldap::NG::Common::UserAgent;
use JSON qw(from_json);

our $VERSION = '2.0.15';
our $_ua;

sub ua {
    my ($class) = @_;
    return $_ua if $_ua;
    $_ua = Lemonldap::NG::Common::UserAgent->new( {
            lwpOpts    => $class->tsv->{lwpOpts},
            lwpSslOpts => $class->tsv->{lwpSslOpts}
        }
    );
    return $_ua;
}

sub checkMaintenanceMode {
    my ( $class, $req ) = @_;
    my $vhost = $class->resolveAlias($req);

    unless ($vhost) {
        $class->logger->error('No VHost provided');
        return $class->Lemonldap::NG::Handler::Main::checkMaintenanceMode($req);
    }

    $class->logger->info("DevOps request from $vhost");
    $class->tsv->{lastVhostUpdate} //= {};
    $class->_loadVhostConfig( $req, $vhost )
      unless (
        $class->tsv->{defaultCondition}->{$vhost}
        and (
            time() - $class->tsv->{lastVhostUpdate}->{$vhost} <
            $class->checkTime )
      );

    return $class->Lemonldap::NG::Handler::Main::checkMaintenanceMode($req);
}

sub _loadVhostConfig {
    my ( $class, $req, $vhost ) = @_;
    my ( $json, $rUrl, $rVhost );
    if ( $class->tsv->{useSafeJail} ) {
        if ( $req->env->{RULES_URL} || $class->tsv->{devOpsRulesUrl}->{$vhost} )
        {
            $rUrl = $req->{env}->{RULES_URL}
              || $class->tsv->{devOpsRulesUrl}->{$vhost};
            $rVhost = ( $rUrl =~ m#^https?://([^/]*).*# )[0];
            $rVhost =~ s/:\d+$//;
        }
        else {
            $rUrl =
              ( $class->localConfig->{loopBackUrl}
                  || "http://127.0.0.1:" . $req->{env}->{SERVER_PORT} )
              . '/rules.json';
            $rVhost = $vhost;
        }

        $class->logger->debug("Try to retrieve rules file from $rUrl");
        my $get = HTTP::Request->new( GET => $rUrl );
        $class->logger->debug("Set Host header with $rVhost");
        $get->header( Host => $rVhost );
        my $resp = $class->ua->request($get);
        if ( $resp->is_success ) {
            $class->logger->debug('Response is success');
            eval { $json = from_json( $resp->content, { allow_nonref => 1 } ); };
            if ($@) {
                $class->logger->debug('Bad json file received');
                $class->logger->error(
"Bad rules file retrieved from $rUrl for $vhost, skipping ($@)"
                );
            }
            else {
                $class->logger->debug('Good json file received');
                $class->logger->info(
                    "Compiling rules retrieved from $rUrl for $vhost");
            }
        }
        else {
            $class->logger->error(
                "Unable to retrieve rules file from $rUrl -> "
                  . $resp->status_line );
            $class->logger->info("Default rule and header are employed");
        }
    }
    else {
        $class->logger->error(
q"I refuse to compile 'rules.json' when useSafeJail isn't activated! Yes I know, I'm a coward..."
        );
    }
    $json->{rules} ||= { default => 1 };
    $json->{headers} //= { 'Auth-User' => '$uid' };

    # Removed hidden session attributes
    foreach my $v ( split /[,\s]+/, $class->tsv->{hiddenAttributes} ) {
        foreach ( keys %{ $json->{headers} } ) {
            delete $json->{headers}->{$_}
              if $json->{headers}->{$_} eq '$' . $v;
        }
    }

    $class->logger->debug("DevOps handler called by $vhost");
    $class->locationRulesInit( undef, { $vhost => $json->{rules} } );
    $class->headersInit( undef, { $vhost => $json->{headers} } );
    $class->tsv->{lastVhostUpdate}->{$vhost} = time;
    $class->tsv->{https}->{$vhost} = uc $req->env->{HTTPS_REDIRECT} eq 'ON'
      if exists $req->env->{HTTPS_REDIRECT};
    $class->tsv->{port}->{$vhost} = $req->env->{PORT_REDIRECT}
      if exists $req->env->{PORT_REDIRECT};

    return;
}

1;
