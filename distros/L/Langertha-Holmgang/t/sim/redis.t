#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command clone need_parts );

# Redis auf dem Linux-Simulator.
# Behauptet wird: redis-cli spricht nur mit einem laufenden, gebundenen Redis
# und verlangt das Passwort; CONFIG GET/SET pruefen wie Redis 7.0 (Bytes,
# Werteliste, unveraenderlich); CONFIG REWRITE schreibt die laufenden Werte in
# die Datei; ein Neustart liest die Datei, sichert vorher (wenn er kann) und
# verwirft sonst Ungesichertes; eine fehlerhafte Datei verhindert den Start;
# BGSAVE scheitert, solange das Verzeichnis nicht schreibbar ist.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $conf = "bind 127.0.0.1 -::1\nport 6379\nmaxmemory 2gb\nmaxmemory-policy noeviction\nsave 3600 1\ndir /var/lib/redis\n";
my $start = {
    cache => {
        type  => 'linux',
        clock => 'Oct 24 09:12',
        users => { redis => { uid => 110, groups => ['redis'] } },
        dirs  => { '/var/lib/redis' => { owner => 'redis', group => 'redis', mode => '0750' } },
        files => { '/etc/redis/redis.conf' => { content => $conf, owner => 'redis', group => 'redis', mode => '0640' } },
        services => { 'redis-server' => { active => JSON::MaybeXS::true(), description => 'Advanced key-value store', exec => 'redis-server' } },
        redis => {
            service => 'redis-server', conf => '/etc/redis/redis.conf', keys => { db0 => 1200 }, saved => { db0 => 1000 },
            used_memory => 2147480000, rdb_changes => 200,
            bgsave_needs => [ { state => [ 'dirs', '/var/lib/redis', 'owner' ], equals => 'redis' } ],
        },
    },
};

my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok, $gap ) = run_command( $state, 'cache', $cmd );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}
my $R = sub { $state->{cache}{redis} };

{
    fresh();
    is( sh('redis-cli ping'), 'PONG', 'PING' );
    is( sh('redis-cli CONFIG GET maxmemory'), qq{1) "maxmemory"\n2) "2147483648"}, 'CONFIG GET in Bytes aus der Datei' );
    like( sh('redis-cli INFO memory'), qr/^maxmemory_policy:noeviction$/m, 'INFO memory' );
    like( sh('redis-cli CONFIG SET maxmemory-policy allkeys-lruu'), qr/\(error\) ERR CONFIG SET failed \(possibly related to argument 'maxmemory-policy'\) - argument\(s\) must be one of/,
        'Werteliste geprueft' );
    like( sh('redis-cli CONFIG SET databases 32'), qr/can't set immutable config/, 'unveraenderlich' );
    is( sh('redis-cli CONFIG SET maxmemory-policy allkeys-lru'), 'OK', 'CONFIG SET' );
    is( $R->()->{running}{'maxmemory-policy'}, 'allkeys-lru', '... laufend' );
    unlike( $state->{cache}{files}{'/etc/redis/redis.conf'}{content}, qr/allkeys-lru/, '... Datei unveraendert' );
    is( sh('redis-cli CONFIG REWRITE'), 'OK', 'CONFIG REWRITE' );
    like( $state->{cache}{files}{'/etc/redis/redis.conf'}{content}, qr/^maxmemory-policy allkeys-lru$/m, '... ersetzt die Zeile' );
    like( $state->{cache}{files}{'/etc/redis/redis.conf'}{content}, qr/^maxmemory 2gb$/m, '... Bytes lesbar' );
    is( sh(q{echo "CONFIG GET maxmemory-policy" | redis-cli --raw}), "maxmemory-policy\nallkeys-lru", 'Befehl auf stdin, --raw' );
    is( sh('redis-cli -h 10.20.0.31 ping'), 'Could not connect to Redis at 10.20.0.31:6379: Connection refused', 'nicht gebundene Adresse' );
    like( sh(q{redis-cli CONFIG SET bind "127.0.0.1,10.20.0.61"}), qr/Failed to bind to specified addresses/, 'bind mit Komma: abgelehnt wie Redis' );
    like( sh('ss -ltnp'), qr/127\.0\.0\.1:6379 .*redis-server/, 'ss zeigt den Lauscher aus bind' );

    # anderer Server: redis-cli -h fragt dessen Redis
    $state->{peer} = clone( $state->{cache} );
    $state->{peer}{interfaces} = { eth0 => { addr => ['10.20.0.71/24'], state => 'UP' } };
    $state->{peer}{redis}{running}{bind} = '127.0.0.1 10.20.0.71';
    $state->{peer}{redis}{keys} = { db0 => 7 };
    is( sh('redis-cli -h 10.20.0.71 DBSIZE'), '(integer) 7', 'redis-cli -h fragt den Redis des anderen Servers' );
}

# --- Passwort, Start, Sicherung ------------------------------------------------
# bgsave_needs ist eine Erwartung auf dem Zustand (Langertha::Holmgang::Expectation, k2)
subtest 'Passwort, Start, Sicherung' => sub {
    my $why = need_parts('+Expectation');
    plan skip_all => $why if $why;
    fresh();
    $state->{cache}{files}{'/etc/redis/redis.conf'}{content} .= "requirepass s3cret\n";
    sh('systemctl restart redis-server');
    is( sh('redis-cli ping'), '(error) NOAUTH Authentication required.', 'NOAUTH ohne Passwort' );
    like( sh('redis-cli -a s3cret ping'), qr/PONG\z/, 'mit -a' );
    is( sh('redis-cli -a s3cret --no-auth-warning ping'), 'PONG', '... ohne Warnung' );
    like( sh('redis-cli -a s3cret --no-auth-warning masterauth geheim'), qr/^\(error\) ERR unknown command 'masterauth'/, 'unbekannter Befehl wie Redis' );
    is( $R->()->{keys}{db0}, 1200, 'Neustart mit schreibbarem Verzeichnis sichert vorher: nichts verloren' );

    fresh();
    $state->{cache}{dirs}{'/var/lib/redis'}{owner} = 'root';
    is( sh('redis-cli BGSAVE'), 'Background saving started', 'BGSAVE startet' );
    like( sh('redis-cli INFO persistence'), qr/^rdb_last_bgsave_status:err$/m, '... scheitert im Kind' );
    sh('chown redis:redis /var/lib/redis');
    like( sh('redis-cli INFO persistence'), qr/^rdb_last_bgsave_status:ok$/m, 'nach chown versucht Redis es selbst neu und es gelingt' );
    like( sh('ls -l /var/lib/redis/dump.rdb'), qr/^-rw-rw---- 1 redis\s+redis .* Oct 24 09:12 /, '... dump.rdb neu geschrieben' );
    is( $R->()->{saved}{db0}, 1200, '... und sichert den Stand' );

    fresh();
    $state->{cache}{dirs}{'/var/lib/redis'}{owner} = 'root';
    sh('redis-cli BGSAVE');
    like( sh('redis-cli SET probe 1'), qr/\(error\) MISCONF/, 'Schreiben gesperrt, solange die Sicherung scheitert' );
    sh('systemctl restart redis-server');
    is( $R->()->{keys}{db0}, 1000, 'Neustart ohne moegliche Sicherung: Ungesichertes ist weg' );
    is( $R->()->{lost}, 200, '... lost zaehlt es' );
    is( sh('redis-cli SET probe 1'), 'OK', 'danach (Sicherung wieder moeglich) SET' );
    is( sh('redis-cli GET probe'), '"1"', 'GET' );
    is( $R->()->{keys}{db0}, 1001, '... zaehlt den Schluessel' );

    fresh();
    $state->{cache}{files}{'/etc/redis/redis.conf'}{content} .= "maxmemory-polcy allkeys-lru\n";
    my ( $o, $ok ) = sh('systemctl restart redis-server');
    ok( !$ok, 'Tippfehler in der Datei: Start scheitert' );
    like( sh('journalctl -u redis-server -n 8'), qr/>>> 'maxmemory-polcy allkeys-lru'.*Bad directive/s, '... Journal nennt die Zeile' );
    is( sh('redis-cli ping'), 'Could not connect to Redis at 127.0.0.1:6379: Connection refused', '... und Redis ist weg' );
    my ( undef, undef, $gap ) = sh('redis-cli --bigkeys');
    ok( $gap, 'nicht nachgebildete Option: Luecke der Simulation' );
};

# --- Umschaltung: Primaer per Adresse ----------------------------------------
# Behauptet: ein Replikat findet seinen Primaer ueber die Adresse in replicaof —
# auch wenn es nach einer Umschaltung auf ein anderes Geraet zeigt.
{
    my $mk = sub {
        my ( $addr, $conf ) = @_;
        return { type => 'linux', interfaces => { eth0 => { addr => ["$addr/24"], state => 'UP' } },
            files => { '/etc/redis/redis.conf' => $conf },
            services => { 'redis-server' => { active => JSON::MaybeXS::true(), exec => 'redis-server', user => 'redis' } },
            redis => { service => 'redis-server', conf => '/etc/redis/redis.conf', keys => { db0 => 10 }, saved => { db0 => 10 } } };
    };
    my $st = {
        r1 => $mk->( '10.20.0.75', "bind 127.0.0.1 10.20.0.75\nport 6379\n" ),
        r2 => $mk->( '10.20.0.76', "bind 127.0.0.1 10.20.0.76\nport 6379\nreplicaof 10.20.0.75 6379\n" ),
    };
    my $run = sub { ( run_command( $st, $_[0], $_[1] ) )[0] };
    like( $run->( 'r2', 'redis-cli INFO replication' ), qr/master_link_status:up/, 'Replikat findet den Primaer per Adresse' );
    like( $run->( 'r2', 'redis-cli SET x 1' ), qr/READONLY You can't write against a read only replica/, 'Replikat nimmt keine Schreibzugriffe' );
    $run->( 'r2', 'redis-cli REPLICAOF NO ONE' );
    $run->( 'r1', 'redis-cli REPLICAOF 10.20.0.76 6379' );
    like( $run->( 'r1', 'redis-cli INFO replication' ), qr/master_host:10\.20\.0\.76\nmaster_port:6379\nmaster_link_status:up/, 'nach der Umschaltung: altes Primaer ist Replikat des neuen' );
    like( $run->( 'r2', 'redis-cli INFO replication' ), qr/role:master/, '... und das neue ist Primaer' );
}

done_testing;
