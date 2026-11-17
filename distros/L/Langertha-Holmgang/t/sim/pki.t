#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command write_file prepare clone diff get throws_ok need_parts );
use Langertha::Holmgang::Sim::Linux::Pki ();

# Zertifikate als Daten. Behauptet wird:
# PEM-Bloecke verweisen auf den Katalog, Dateien bleiben Text (cat a b >
# kette); openssl x509/rsa/verify/s_client/req antworten wie OpenSSL 3; nginx
# laedt Blatt + Kette aus ssl_certificate und weist einen unpassenden oder
# verschluesselten Schluessel ab; der Client (curl) prueft Kette, Gueltigkeit
# und Namen gegen seinen Vertrauensspeicher; update-ca-certificates nimmt
# nur *.crt; ein erneuertes Zertifikat wirkt erst nach reload.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $T = JSON::MaybeXS::true();
my $P = \&Langertha::Holmgang::Sim::Linux::Pki::pem;
my $SITE = <<'S';
server {
    listen 443 ssl;
    server_name shop.example.com;
    ssl_certificate /etc/ssl/shop/cert.pem;
    ssl_certificate_key /etc/ssl/shop/privkey.pem;
    location / { return 200 "ok\n"; }
}
S
my $start = {
    web1 => {
        type => 'linux',
        interfaces => { eth0 => { addr => ['10.20.0.31/24'] } },
        services => { nginx => { active => $T } },
        nginx => {},
        files => {
            '/etc/nginx/nginx.conf' => "events {}\nhttp {\n    include /etc/nginx/sites-enabled/*;\n}\n",
            '/etc/nginx/sites-enabled/shop' => $SITE,
            '/etc/ssl/shop/cert.pem' => $P->( cert => 'shop' ),
            '/etc/ssl/shop/chain.pem' => $P->( cert => 'r3' ),
            '/etc/ssl/shop/privkey.pem' => $P->( key => 'k-shop' ),
            '/etc/ssl/shop/other.key' => $P->( key => 'k-other' ),
            '/etc/ssl/shop/enc.key' => $P->( enckey => 'k-shop' ),
        },
        pki => {
            now => '2026-10-24T08:00:00Z',
            certs => {
                shop => { subject => 'CN=shop.example.com', sans => ['shop.example.com'], issuer => 'r3', key => 'k-shop',
                    not_before => '2026-09-01T00:00:00Z', not_after => '2026-11-30T00:00:00Z' },
                old => { subject => 'CN=shop.example.com', sans => ['shop.example.com'], issuer => 'r3', key => 'k-shop',
                    not_before => '2026-06-01T00:00:00Z', not_after => '2026-08-30T00:00:00Z' },
                r3 => { subject => 'C=US,O=Example Trust,CN=Example R3', issuer => 'x1', ca => $T, key => 'k-r3',
                    not_before => '2025-01-01T00:00:00Z', not_after => '2028-01-01T00:00:00Z' },
                x1 => { subject => 'C=US,O=Example Trust,CN=Example Root X1', issuer => 'x1', ca => $T, key => 'k-x1',
                    not_before => '2020-01-01T00:00:00Z', not_after => '2035-01-01T00:00:00Z' },
                ica => { subject => 'O=Example Intern,CN=Example Intern CA', issuer => 'ica', ca => $T, key => 'k-ica',
                    not_before => '2024-01-01T00:00:00Z', not_after => '2034-01-01T00:00:00Z' },
            },
            keys => { 'k-shop' => { bits => 2048, passphrase => 'geheim' }, 'k-other' => {}, 'k-r3' => {}, 'k-x1' => {}, 'k-ica' => {} },
        },
    },
    client1 => {
        type => 'linux',
        interfaces => { eth0 => { addr => ['10.20.0.50/24'] } },
        files => { '/etc/hosts' => "10.20.0.31 shop.example.com www.shop.example.com\n", '/root/ica.pem' => $P->( cert => 'ica' ) },
        pki => { trusted => ['x1'] },
        probes => { shop => { url => 'https://shop.example.com/' } },
    },
};

my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ( $host, $cmd ) = @_;
    my ( $o, $ok ) = run_command( $state, $host, $cmd );
    return wantarray ? ( $o, $ok ) : $o;
}

fresh();
like( $P->( cert => 'shop' ), qr/\A-----BEGIN CERTIFICATE-----\n[A-Za-z0-9+\/=\n]+\n-----END CERTIFICATE-----\n\z/, 'pem: Block mit Base64-Rumpf' );
is( sh( 'web1', 'openssl x509 -in /etc/ssl/shop/cert.pem -noout -subject -issuer' ),
    "subject=CN = shop.example.com\nissuer=C = US, O = Example Trust, CN = Example R3", 'x509 -subject -issuer wie OpenSSL 3' );
is( sh( 'web1', 'openssl x509 -in /etc/ssl/shop/cert.pem -noout -enddate' ), 'notAfter=Nov 30 00:00:00 2026 GMT', 'x509 -enddate' );
my ( $o, $ok ) = sh( 'web1', 'openssl x509 -in /etc/ssl/shop/cert.pem -noout -checkend 604800' );
ok( $ok && $o eq 'Certificate will not expire', 'checkend gegen pki.now' );
is( sh( 'web1', 'openssl x509 -in /etc/ssl/shop/cert.pem -noout -modulus | openssl md5' ),
    sh( 'web1', 'openssl rsa -in /etc/ssl/shop/privkey.pem -noout -modulus | openssl md5' ), 'Modulus von Zertifikat und Schluessel gleich' );
isnt( sh( 'web1', 'openssl rsa -in /etc/ssl/shop/other.key -noout -modulus' ), sh( 'web1', 'openssl x509 -in /etc/ssl/shop/cert.pem -noout -modulus' ),
    '... fremder Schluessel: anderer Modulus' );

# Kette, verify
like( sh( 'web1', 'openssl verify -CAfile /etc/ssl/shop/chain.pem /etc/ssl/shop/cert.pem' ), qr/error 2 at|error 20 at 1 depth lookup: unable to get local issuer certificate/,
    'verify: Zwischen- ist kein Wurzelzertifikat' );
sh( 'web1', 'cat /etc/ssl/shop/cert.pem /etc/ssl/shop/chain.pem > /etc/ssl/shop/fullchain.pem' );
like( sh( 'web1', 'openssl crl2pkcs7 -nocrl -certfile /etc/ssl/shop/fullchain.pem | openssl pkcs7 -print_certs -noout' ),
    qr/\Asubject=CN = shop.example.com\nissuer=.*R3\n\nsubject=.*CN = Example R3\nissuer=.*Root X1\z/, 'cat baut die Kette, pkcs7 -print_certs zeigt sie' );

# nginx: Kette fehlt -> Client scheitert
like( $state->{client1}{probes}{shop}{result}{error}, qr/\A\(60\) SSL certificate problem: unable to get local issuer certificate\z/, 'nur Blatt: Client scheitert' );
like( sh( 'client1', 'curl -sS https://shop.example.com/' ), qr/unable to get local issuer certificate/, '... curl meldet es' );
is( sh( 'client1', 'curl -sk https://shop.example.com/' ), 'ok', '... mit -k geht es' );
my $s = $state->{web1}{files}{'/etc/nginx/sites-enabled/shop'};
$s =~ s{/etc/ssl/shop/cert.pem}{/etc/ssl/shop/fullchain.pem};
write_file( $state, 'web1', '/etc/nginx/sites-enabled/shop', $s );
is( $state->{client1}{probes}{shop}{result}{status}, 0, 'nur Datei geaendert: noch die alte Kette' );
sh( 'web1', 'systemctl reload nginx' );
is( $state->{client1}{probes}{shop}{result}{status}, 200, 'nach reload: Kette vollstaendig' );
like( sh( 'client1', 'openssl s_client -connect shop.example.com:443 -servername shop.example.com </dev/null' ), qr/Verify return code: 20|Verification error/,
    's_client ohne Vertrauen in die Wurzel des Clients? (client1 hat x1)' ) if 0;
like( sh( 'client1', 'openssl s_client -connect shop.example.com:443 -servername shop.example.com </dev/null' ), qr/Verify return code: 0 \(ok\)/, 's_client: Kette ok' );
like( sh( 'client1', 'curl -sS https://www.shop.example.com/' ), qr/no alternative certificate subject name matches target host name 'www.shop.example.com'/, 'Name fehlt im Zertifikat' );

# Reihenfolge falsch, Schluessel passt nicht, verschluesselt
fresh();
sh( 'web1', 'cat /etc/ssl/shop/chain.pem /etc/ssl/shop/cert.pem > /etc/ssl/shop/cert.pem.neu && mv /etc/ssl/shop/cert.pem.neu /etc/ssl/shop/cert.pem' );
( $o, $ok ) = sh( 'web1', 'nginx -t' );
like( $o, qr/\Anginx: \[emerg\] SSL_CTX_use_PrivateKey\("\/etc\/ssl\/shop\/privkey.pem"\) failed \(SSL: error:05800074:x509 certificate routines::key values mismatch\)/, 'Zwischenzertifikat zuerst: key values mismatch' );
fresh();
$state->{web1}{files}{'/etc/nginx/sites-enabled/shop'} =~ s/privkey\.pem/enc.key/;
like( sh( 'web1', 'nginx -t' ), qr/problems getting password/, 'verschluesselter Schluessel ohne ssl_password_file' );
$state->{web1}{files}{'/etc/nginx/sites-enabled/shop'} =~ s/(ssl_certificate_key[^\n]+\n)/$1    ssl_password_file \/etc\/nginx\/keypass;\n/;
$state->{web1}{files}{'/etc/nginx/keypass'} = "geheim\n";
ok( ( sh( 'web1', 'nginx -t' ) )[1], '... mit ssl_password_file geht es' );
( $o, $ok ) = sh( 'web1', 'openssl rsa -in /etc/ssl/shop/enc.key -out /etc/ssl/shop/plain.key' );
ok( !$ok && $o =~ /Enter pass phrase/, 'rsa ohne -passin scheitert (nicht interaktiv)' );
( $o, $ok ) = sh( 'web1', 'openssl rsa -in /etc/ssl/shop/enc.key -passin pass:geheim -out /etc/ssl/shop/plain.key' );
ok( $ok, 'rsa -passin pass: entschluesselt' );
like( $state->{web1}{files}{'/etc/ssl/shop/plain.key'}{content}, qr/\A-----BEGIN PRIVATE KEY-----/, '... in eine unverschluesselte Datei' );
is( $state->{web1}{files}{'/etc/ssl/shop/plain.key'}{mode}, '0600', '... neu angelegt mit 0600 wie OpenSSL 3' );
ok( !( sh( 'web1', 'openssl pkey -in /etc/ssl/shop/enc.key -passin pass:falsch -noout' ) )[1], 'falsche Passphrase' );

# abgelaufen, CA vertrauen
fresh();
$state->{web1}{files}{'/etc/ssl/shop/cert.pem'} = $P->( cert => 'old' ) . $P->( cert => 'r3' );
sh( 'web1', 'systemctl reload nginx' );
like( $state->{client1}{probes}{shop}{result}{error}, qr/certificate has expired/, 'abgelaufen' );
$state->{client1}{probes}{intern} = { url => 'https://shop.example.com/', cacert => '/root/ica.pem' };
fresh();
$state->{web1}{pki}{certs}{ishop} = { subject => 'CN=shop.example.com', sans => ['shop.example.com'], issuer => 'ica', key => 'k-shop',
    not_before => '2026-01-01T00:00:00Z', not_after => '2027-01-01T00:00:00Z' };
$state->{web1}{files}{'/etc/ssl/shop/cert.pem'} = $P->( cert => 'ishop' );
sh( 'web1', 'systemctl reload nginx' );
like( $state->{client1}{probes}{shop}{result}{error}, qr/unable to get local issuer certificate/, 'interne CA unbekannt' );
SKIP: {
    my $why = need_parts('Backup');    # cp
    skip $why, 3 if $why;
    sh( 'client1', 'cp /root/ica.pem /usr/local/share/ca-certificates/intern.pem && update-ca-certificates' );
    like( $state->{client1}{probes}{shop}{result}{error} // '', qr/unable to get local issuer/, '.pem-Endung: update-ca-certificates nimmt sie nicht (wie Debian)' );
    ( $o, $ok ) = sh( 'client1', 'cp /root/ica.pem /usr/local/share/ca-certificates/intern.crt && update-ca-certificates' );
    like( $o, qr/1 added, 0 removed; done\./, 'update-ca-certificates: 1 added' );
    is( $state->{client1}{probes}{shop}{result}{status}, 200, '... danach vertraut' );
}
is( sh( 'client1', 'curl -s --cacert /root/ica.pem https://shop.example.com/' ), 'ok', '--cacert ersetzt den Speicher' );

# update-ca-certificates ohne cp: die Dateien liegen schon im Verzeichnis
{
    my $c = clone( $start->{client1} );
    $c->{files}{'/usr/local/share/ca-certificates/a.pem'} = $P->( cert => 'ica' );
    my $st = { client1 => $c, web1 => clone( $start->{web1} ) };
    my ( $out, $good ) = run_command( $st, 'client1', 'update-ca-certificates' );
    ok( $good && $out =~ /^0 added, 0 removed; done\.$/m && !$c->{pki}{installed}, '.pem: nicht installiert' );
    $c->{files}{'/usr/local/share/ca-certificates/a.crt'} = $P->( cert => 'ica' );
    ( $out, $good ) = run_command( $st, 'client1', 'update-ca-certificates' );
    like( $out, qr/^1 added, 0 removed; done\.$/m, '.crt: 1 added' );
    is_deeply( $c->{pki}{installed}, ['ica'], '... im Vertrauensspeicher' );
}

# req
fresh();
( $o, $ok ) = sh( 'web1', q{openssl req -new -key /etc/ssl/shop/privkey.pem -subj "/CN=shop.example.com" -addext "subjectAltName=DNS:shop.example.com,DNS:www.shop.example.com" -out /root/shop.csr} );
ok( $ok, 'req -new -subj -addext' ) or diag $o;
is( $state->{web1}{files}{'/root/shop.csr'}, Langertha::Holmgang::Sim::Linux::Pki::csr_pem_for( subject => 'CN=shop.example.com',
    sans => [ 'www.shop.example.com', 'shop.example.com' ], key => 'k-shop' ), 'CSR kanonisch (Reihenfolge der Namen egal)' );
like( sh( 'web1', 'openssl req -in /root/shop.csr -noout -text' ), qr/DNS:shop.example.com, DNS:www.shop.example.com/, 'req -text zeigt die Namen' );
write_file( $state, 'web1', '/root/req.cnf',
    "[req]\nprompt = no\ndistinguished_name = dn\nreq_extensions = ext\n[dn]\nCN = shop.example.com\n[ext]\nsubjectAltName = \@alt\n[alt]\nDNS.1 = www.shop.example.com\nDNS.2 = shop.example.com\n" );
( $o, $ok ) = sh( 'web1', 'openssl req -new -key /etc/ssl/shop/privkey.pem -config /root/req.cnf -out /root/b.csr' );
is( $state->{web1}{files}{'/root/b.csr'}, $state->{web1}{files}{'/root/shop.csr'}, 'gleiche CSR ueber -config' );
( $o, $ok ) = sh( 'web1', 'openssl req -x509 -newkey rsa:2048 -nodes -keyout /root/s.key -out /root/s.crt -days 30 -subj /CN=staging.example.com' );
ok( $ok, 'req -x509 -newkey: selbst signiert' );
like( sh( 'web1', 'openssl x509 -in /root/s.crt -noout -subject -enddate' ), qr/subject=CN = staging.example.com\nnotAfter=Nov 23 08:00:00 2026 GMT/, '... mit Laufzeit' );
done_testing;
