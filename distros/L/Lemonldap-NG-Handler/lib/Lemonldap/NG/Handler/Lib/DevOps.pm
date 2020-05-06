package Lemonldap::NG::Handler::Lib::DevOps;

use strict;
use Lemonldap::NG::Common::UserAgent;
use JSON qw(from_json);

our $VERSION = '2.0.0';

our $_ua;

our $time;

sub ua {
    return $_ua if ($_ua);
    return $_ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->localConfig );
}

sub grant {
    my ( $class, $req, $session, $uri, $cond, $vhost ) = @_;
    $vhost ||= $class->resolveAlias($req);
    $class->tsv->{lastVhostUpdate} //= {};
    unless (
        $class->tsv->{defaultCondition}->{$vhost}
        and (
            time() - $class->tsv->{lastVhostUpdate}->{$vhost} <
            $class->tsv->{checkTime} )
      )
    {
        $class->loadVhostConfig( $req, $vhost );
    }
    return $class->Lemonldap::NG::Handler::Main::grant( $req, $session, $uri,
        $cond, $vhost );
}

sub loadVhostConfig {
    my ( $class, $req, $vhost ) = @_;
    my $json;
    if ( $class->tsv->{useSafeJail} ) {
        my $rUrl = $req->{env}->{RULES_URL}
          || ( (
                $class->localConfig->{loopBackUrl}
                || "http://127.0.0.1:" . $req->{env}->{SERVER_PORT}
            )
            . '/rules.json'
          );
        my $get = HTTP::Request->new( GET => $rUrl );
        $get->header( Host => $vhost );
        my $resp = $class->ua->request($get);
        if ( $resp->is_success ) {
            eval {
                $json = from_json( $resp->content, { allow_nonref => 1 } ); };
            if ($@) {
                $class->logger->error(
                    "Bad rules.json for $vhost, skipping ($@)");
            }
            else {
                $class->logger->info("Compiling rules.json for $vhost");
            }
        }
    }
    else {
        $class->logger->error(
q"I refuse to compile rules.json when useSafeJail isn't activated! Yes I know, I'm a coward..."
        );
    }
    $json->{rules} ||= { default => 1 };
    $json->{headers} //= { 'Auth-User' => '$uid' };
    $class->locationRulesInit( undef, { $vhost => $json->{rules} } );
    $class->headersInit( undef,       { $vhost => $json->{headers} } );
    $class->tsv->{lastVhostUpdate}->{$vhost} = time;
    return;
}

1;
