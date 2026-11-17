#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Holmgang::TestSim qw( run_command write_file clone );


# Kubernetes-Simulator: kubectl set env wie kubectl 1.30.
# Behauptet wird: (1) ohne -c gilt die Zuweisung fuer jeden
# Container, mit -c/--containers NAME (auch NAME=, Komma-Liste, *) nur fuer
# diese; ein unbekannter Container ist ein Fehler und aendert nichts;
# (2) --from=secret/NAME legt je Schluessel eine Variable mit secretKeyRef an
# (Name: Schluessel gross, ungueltige Zeichen als _, davor --prefix), --keys
# waehlt Schluessel aus; ein fehlendes Secret oder ein fehlender Schluessel ist
# ein Fehler; (3) NAME- entfernt eine Variable; --list liest nur.

my $start = {
    adm => {
        type       => 'linux',
        kubernetes => {
            context => 'prod', default_namespace => 'default', registry => ['r/app:1', 'r/side:1'],
            nodes   => { n1 => { ready => 1 } },
            namespaces => {
                default => {},
                fin     => {
                    deployments => {
                        billing => {
                            replicas => 1, generation => 3, selector => { app => 'billing' },
                            template => { labels => { app => 'billing' }, containers => [
                                { name => 'app', image => 'r/app:1', env => [ { name => 'LOG_LEVEL', value => 'info' } ] },
                                { name => 'side', image => 'r/side:1' } ] },
                        },
                    },
                    secrets => { 'mail-creds' => { password => 'geheim', 'smtp-user' => 'relay' } },
                },
            },
        },
    },
};
my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok ) = run_command( $state, 'adm', $cmd );
    return ( $o, $ok );
}
sub cs  { $state->{adm}{kubernetes}{namespaces}{fin}{deployments}{billing}{template}{containers} }
sub gen { $state->{adm}{kubernetes}{namespaces}{fin}{deployments}{billing}{generation} }

# --- (1) Container -----------------------------------------------------------
for my $flag ( '-c app', '--containers=app', '--containers app', '-c=app' ) {
    fresh();
    my ( $o, $ok ) = sh("kubectl -n fin set env deploy/billing $flag MODE=fast");
    ok( $ok, "set env $flag gelingt" ) or diag $o;
    is_deeply( [ map { $_->{value} } grep { $_->{name} eq 'MODE' } @{ cs()->[0]{env} } ], ['fast'], "... $flag: im Container app" );
    ok( !grep( { $_->{name} eq 'MODE' } @{ cs()->[1]{env} || [] } ), "... $flag: nicht im Sidecar" );
}
fresh();
sh('kubectl -n fin set env deploy/billing MODE=fast');
ok( ( grep { $_->{name} eq 'MODE' } @{ cs()->[1]{env} || [] } ), 'ohne -c: auch im Sidecar (wie kubectl)' );
fresh();
my ( $o, $ok ) = sh('kubectl -n fin set env deploy/billing -c gibtsnicht MODE=fast');
ok( !$ok, 'unbekannter Container: Fehler' );
is( gen(), 3, '... und keine Aenderung' );

# --- (2) --from=secret ---------------------------------------------------------
fresh();
( $o, $ok ) = sh('kubectl -n fin set env deploy/billing -c app --from=secret/mail-creds --keys=password --prefix=SMTP_');
ok( $ok, '--from=secret --keys --prefix gelingt' ) or diag $o;
is_deeply( ( grep { $_->{name} eq 'SMTP_PASSWORD' } @{ cs()->[0]{env} } )[0], { name => 'SMTP_PASSWORD', secret => 'mail-creds', key => 'password' },
    '... SMTP_PASSWORD als Verweis auf das Secret, kein Klartext' );
is( scalar( grep { $_->{name} =~ /USER/ } @{ cs()->[0]{env} } ), 0, '... nur der gewaehlte Schluessel' );
is( gen(), 4, '... neue Vorlage (generation)' );
fresh();
sh('kubectl -n fin set env deploy/billing -c app --from secret/mail-creds');
is_deeply( [ sort map { $_->{name} } @{ cs()->[0]{env} } ], [qw( LOG_LEVEL PASSWORD SMTP_USER )], 'ohne --keys: alle Schluessel, - wird _' );
fresh();
( $o, $ok ) = sh('kubectl -n fin set env deploy/billing --from=secret/fehlt');
ok( !$ok && $o =~ /secrets "fehlt" not found/, 'fehlendes Secret: NotFound' ) or diag $o;
( $o, $ok ) = sh('kubectl -n fin set env deploy/billing --from=secret/mail-creds --keys=token');
ok( !$ok && gen() == 3, 'fehlender Schluessel: Fehler, keine Aenderung' ) or diag $o;

# --- --list liest nur ------------------------------------------------------------
fresh();
sh('kubectl -n fin set env deploy/billing -c app --from=secret/mail-creds --keys=password --prefix=SMTP_');
( $o, $ok ) = sh('kubectl -n fin set env deploy/billing --list');
ok( $ok, '--list gelingt' ) or diag $o;
like( $o, qr/^# deployments\/billing, container app\nLOG_LEVEL=info\n# SMTP_PASSWORD from secret mail-creds, key password$/m, '... zeigt Werte und Verweise' );
like( $o, qr/^# deployments\/billing, container side$/m, '... je Container' );
is( gen(), 4, '... aendert nichts' );

# --- (3) NAME- -----------------------------------------------------------------
fresh();
( $o, $ok ) = sh('kubectl -n fin set env deploy/billing -c app LOG_LEVEL-');
ok( $ok, 'NAME- gelingt' ) or diag $o;
is_deeply( cs()->[0]{env}, [], '... Variable entfernt' );

done_testing;
