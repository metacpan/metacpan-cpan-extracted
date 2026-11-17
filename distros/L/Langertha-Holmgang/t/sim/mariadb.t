#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON::MaybeXS ();

use Holmgang::TestSim qw( run_command prepare clone );

# MariaDB auf dem Linux-Simulator.
# Behauptet wird: root kommt ueber unix_socket hinein, andere Konten nur mit
# Passwort und passendem Host; SET GLOBAL nur fuer dynamische Variablen, der
# Rest erst nach Neustart aus den Optionsdateien; eine unbekannte Variable
# verhindert den Start; bei max_connections bekommt nur SUPER noch eine
# Verbindung; GRANT/REVOKE/SHOW GRANTS rechnen auf Rechtelisten; PURGE und rm
# von Binlogs, die ein Replikat noch liest, brechen es; das Replikat laeuft nach
# sql_slave_skip_counter und START SLAVE weiter.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $cnf = "[server]\n\n[mysqld]\nuser = mysql\nbind-address = 127.0.0.1\nmax_connections = 151\nlog_bin = /var/log/mysql/mariadb-bin\n";
my $start = {
    db1 => {
        type  => 'linux',
        clock => 'Oct 24 09:12',
        users => { mysql => { uid => 107, groups => ['mysql'] } },
        groups => { mysql => { gid => 113 } },
        files => {
            '/etc/mysql/mariadb.conf.d/50-server.cnf' => $cnf,
            '/var/lib/mysql/mariadb-bin.000410' => { size => '1G', owner => 'mysql', group => 'mysql', mode => '0660', content => '' },
            '/var/lib/mysql/mariadb-bin.000411' => { size => '1G', owner => 'mysql', group => 'mysql', mode => '0660', content => '' },
            '/var/lib/mysql/mariadb-bin.000412' => { size => '1G', owner => 'mysql', group => 'mysql', mode => '0660', content => '' },
        },
        services => { mariadb => { active => JSON::MaybeXS::true(), description => 'MariaDB 10.11.6 database server', exec => 'mariadbd' } },
        mariadb => {
            service => 'mariadb', conf => ['/etc/mysql/mariadb.conf.d/50-server.cnf'],
            status  => { Threads_connected => 151, Max_used_connections => 151 },
            users   => { 'root@localhost' => { auth => 'unix_socket' }, 'app@10.20.0.%' => { password => 'pw1', grants => ['ALL PRIVILEGES ON `shop`.*'] },
                'app@localhost' => { password => 'pw1', grants => ['ALL PRIVILEGES ON `shop`.*'] } },
            databases   => ['shop'],
            processlist => [ { id => 1001, user => 'app', host => '10.20.0.21:41234', db => 'shop', command => 'Sleep', time => 12, count => 150 } ],
            binlogs     => [ { name => 'mariadb-bin.000410' }, { name => 'mariadb-bin.000411' }, { name => 'mariadb-bin.000412' } ],
            replicas    => { db2 => 'mariadb-bin.000411' },
        },
    },
};

my $state;
sub fresh { $state = clone($start) }
sub sh {
    my ($cmd) = @_;
    my ( $o, $ok, $gap ) = run_command( $state, 'db1', $cmd );
    return wantarray ? ( $o, $ok, $gap ) : $o;
}
my $M = sub { $state->{db1}{mariadb} };

{
    fresh();
    is( sh(q{mysql -N -e "SELECT @@max_connections"}), '151', 'root ueber unix_socket, -N' );
    is( sh(q{mysql -e "SHOW VARIABLES LIKE 'bind_address'"}), "Variable_name\tValue\nbind_address\t127.0.0.1", 'SHOW VARIABLES LIKE (Tabulator wie ohne Terminal)' );
    is( ( sh(q{mysql -u app -ppw1 -e "SELECT 1"}) )[0], 'ERROR 1040 (HY000): Too many connections', 'voll: app bekommt keine Verbindung' );
    like( sh(q{mysql -e "SET GLOBAL bind_address = '0.0.0.0'"}), qr/ERROR 1238 .* read only variable/, 'statische Variable' );
    is( ( sh(q{mysql -e "SET GLOBAL max_connections = 500"}) )[1], 1, 'SET GLOBAL dynamisch' );
    is( $M->()->{variables}{max_connections}, '500', '... laufend' );
    like( ( sh(q{mysql -u app -ppw1 -e "SHOW DATABASES"}) )[0], qr/shop/, 'jetzt bekommt app eine Verbindung' );
    is( ( sh(q{mysql -u app -pfalsch -e "SELECT 1"}) )[0], "ERROR 1045 (28000): Access denied for user 'app'\@'localhost' (using password: YES)", 'falsches Passwort' );
    sh('systemctl restart mariadb');
    is( $M->()->{variables}{max_connections}, '151', 'Neustart: wieder aus der Datei' );
    is( $M->()->{status}{Threads_connected}, 1, '... Verbindungen neu' );
}

# --- Optionsdateien und Start ---------------------------------------------------
{
    fresh();
    $state->{db1}{files}{'/etc/mysql/mariadb.conf.d/50-server.cnf'} .= "innodb_buffer_pool_szie = 4G\n";
    my ( $o, $ok ) = sh('systemctl restart mariadb');
    ok( !$ok, 'unbekannte Variable: Start scheitert' );
    like( sh('journalctl -u mariadb -n 6'), qr/unknown variable 'innodb_buffer_pool_szie=4G'/, '... Journal nennt sie' );
    like( ( sh('mysql -e "SELECT 1"') )[0], qr/ERROR 2002/, '... Server weg' );
    sh(q{sed -i 's/innodb_buffer_pool_szie/innodb_buffer_pool_size/' /etc/mysql/mariadb.conf.d/50-server.cnf});
    ok( ( sh('systemctl start mariadb') )[1], 'korrigiert: startet' );
    is( $M->()->{variables}{innodb_buffer_pool_size}, 4 * 1024**3, '... mit dem Wert' );

    $state->{db1}{dirs}{'/srv/tmp'} = { owner => 'root', group => 'root', mode => '0755' };
    $state->{db1}{files}{'/etc/mysql/mariadb.conf.d/50-server.cnf'} .= "tmpdir = /srv/tmp\n";
    ok( !( sh('systemctl restart mariadb') )[1], 'tmpdir nicht fuer mysql schreibbar: Start scheitert' );
    like( sh('journalctl -u mariadb -n 8'), qr/Errcode: 13/, '... Journal nennt es' );
    sh('chown mysql:mysql /srv/tmp');
    ok( ( sh('systemctl start mariadb') )[1], 'nach chown startet mariadb' );
}

# --- prepare: laufende Werte aus dem Anfangszustand ------------------------------------
{
    fresh();
    prepare($state);
    $state->{db1}{files}{'/etc/mysql/mariadb.conf.d/50-server.cnf'} =~ s/max_connections = 151/max_connections = 400/;
    is( sh(q{mysql -N -e "SELECT @@max_connections"}), '151', 'nach prepare: Datei geaendert, Server laeuft mit dem alten Wert' );
}

# --- Benutzer und Rechte -----------------------------------------------------------
{
    fresh();
    sh(q{mysql -e "CREATE USER 'report'@'10.20.0.50' IDENTIFIED BY 'r3p'; GRANT SELECT ON shop.* TO 'report'@'10.20.0.50'"});
    is_deeply( $M->()->{users}{'report@10.20.0.50'}{grants}, ['SELECT ON `shop`.*'], 'CREATE USER + GRANT' );
    like( sh(q{mysql -N -e "SHOW GRANTS FOR 'report'@'10.20.0.50'"}), qr/^GRANT SELECT ON `shop`\.\* TO `report`@`10\.20\.0\.50`$/m, 'SHOW GRANTS' );
    sh(q{mysql -e 'GRANT INSERT, select ON `shop`.* TO "report"@"10.20.0.50"'});
    is_deeply( $M->()->{users}{'report@10.20.0.50'}{grants}, ['SELECT, INSERT ON `shop`.*'], 'GRANT ergaenzt' );
    sh(q{mysql -e "REVOKE INSERT ON shop.* FROM 'report'@'10.20.0.50'"});
    is_deeply( $M->()->{users}{'report@10.20.0.50'}{grants}, ['SELECT ON `shop`.*'], 'REVOKE' );
    like( ( sh(q{mysql -e "CREATE USER 'report'@'10.20.0.50'"}) )[0], qr/ERROR 1396/, 'doppelt angelegt' );
    my ($hash) = sh(q{mysql -N -e "SHOW GRANTS FOR 'app'@'localhost'"}) =~ /IDENTIFIED BY PASSWORD '(\*[0-9A-F]{40})'/;
    ok( $hash, 'SHOW GRANTS zeigt den Hash' );
    sh(qq{mysql -e "CREATE USER 'app'\@'10.20.0.22' IDENTIFIED BY PASSWORD '$hash'"});
    is( $M->()->{users}{'app@10.20.0.22'}{password}, 'pw1', 'IDENTIFIED BY PASSWORD mit dem Hash uebernimmt das Passwort' );
    is( sh(q{mysql -N -e "SELECT @@innodb_buffer_pool_size/1024/1024 AS mb, @@max_connections"}), "128.0000\t151", 'SELECT mit Rechnung und Alias' );
    sh(q{mysql -e "SET GLOBAL max_allowed_packet = 64*1024*1024"});
    is( $M->()->{variables}{max_allowed_packet}, 67108864, 'SET GLOBAL mit Rechnung' );
    is( sh(q{mysql -N -e "SELECT user, host FROM mysql.user WHERE user LIKE 'rep%'"}), "report\t10.20.0.50", 'mysql.user mit LIKE' );
    like( sh(q{mysql -N -e "SELECT user, authentication_string FROM mysql.user WHERE user = 'app' AND host = 'localhost'"}), qr/^app\t\*[0-9A-F]{40}$/, 'authentication_string' );
    like( sh(q{mysql -N -e "SHOW CREATE USER 'app'@'localhost'"}), qr/^CREATE USER `app`\@`localhost` IDENTIFIED BY PASSWORD '\*[0-9A-F]{40}'$/, 'SHOW CREATE USER' );
    is( sh(q{mysql -N -e "SELECT User, Host, Db, Select_priv FROM mysql.db WHERE User='app'"}), "app\t10.20.0.%\tshop\tY\napp\tlocalhost\tshop\tY", 'mysql.db aus den Grants' );
    is( sh(q{mysql -N -e "SELECT 1"}), '1', 'SELECT 1' );
    is( sh(q{mysql -N -e "SELECT USER()"}), 'root@localhost', 'SELECT USER()' );
    $M->()->{tables}{'shop.bestellungen'} = { columns => [qw( id kunde )], rows => [ [ 77119, 'K-7' ], [ 77120, 'K-9' ] ] };
    is( sh(q{mysql -N -e "SELECT * FROM shop.bestellungen WHERE id=77120"}), "77120\tK-9", 'Anwendungstabelle aus dem Fall' );
    is( sh(q{mysql -N -e "SELECT COUNT(*) FROM shop.bestellungen"}), '2', 'COUNT(*)' );
    my ( $o, $ok, $gap ) = sh(q{mysql -N -e "SELECT * FROM shop.kunden"});
    like( $gap, qr/shop\.kunden/, 'unbekannte Tabelle: Luecke' );
    like( ( sh(q{mysql -N -e "SELECT * FROM lager.x"}) )[0], qr/ERROR 1049/, 'unbekannte Datenbank' );
    like( sh(q{mysql -e "SELECT user, host FROM mysql.user"}), qr/^report\t10\.20\.0\.50$/m, 'mysql.user' );
}

# --- Binlogs und Replikat -------------------------------------------------------------
{
    fresh();
    like( sh(q{mysql -e "SHOW BINARY LOGS"}), qr/^mariadb-bin\.000410\t1073741824$/m, 'SHOW BINARY LOGS mit Groesse' );
    sh(q{mysql -e "PURGE BINARY LOGS TO 'mariadb-bin.000411'"});
    is_deeply( [ map { $_->{name} } @{ $M->()->{binlogs} } ], [qw( mariadb-bin.000411 mariadb-bin.000412 )], 'PURGE TO' );
    ok( !exists $state->{db1}{files}{'/var/lib/mysql/mariadb-bin.000410'}, '... Datei weg' );
    ok( !$M->()->{broken_replicas}, '... Replikat liest 000411 weiter' );
    sh(q{mysql -e "PURGE BINARY LOGS TO 'mariadb-bin.000412'"});
    is_deeply( $M->()->{broken_replicas}, { db2 => 'mariadb-bin.000411' }, 'zu weit: Replikat gebrochen' );

    fresh();
    sh('rm /var/lib/mysql/mariadb-bin.000411');
    is_deeply( $M->()->{broken_replicas}, { db2 => 'mariadb-bin.000411' }, 'rm von Hand: ebenso' );

    fresh();
    $M->()->{replica} = { master_host => '10.20.0.31', io => 'Yes', sql => 'No', last_errno => 1062, last_error => "Error 'Duplicate entry '77' for key 'PRIMARY''" };
    like( sh(q{mysql -e "SHOW SLAVE STATUS\G"}), qr/Slave_SQL_Running: No.*Last_Errno: 1062/s, 'SHOW SLAVE STATUS\G senkrecht' );
    sh(q{mysql -e "STOP SLAVE; SET GLOBAL sql_slave_skip_counter = 1; START SLAVE"});
    like( sh(q{mysql -e "SHOW SLAVE STATUS\G"}), qr/Slave_SQL_Running: Yes/, 'nach skip_counter laeuft das Replikat' );
    my ( undef, undef, $gap ) = sh(q{mysql -e "OPTIMIZE TABLE shop.orders"});
    ok( $gap, 'nicht nachgebildetes SQL: Luecke der Simulation' );
}

# --- parallele Replikation ----------------------------------------------------
# Behauptet: slave_parallel_threads laesst sich nur bei angehaltenem SQL-Thread
# setzen (1198), auch unter dem Alias replica_parallel_threads; nach START holt das
# Replikat auf (behind_parallel).
{
    fresh();
    $M->()->{replica} = { master_host => '10.20.0.31', io => 'Yes', sql => 'Yes', behind => 14400, behind_parallel => 30 };
    like( ( sh(q{mysql -e "SET GLOBAL slave_parallel_threads = 4"}) )[0], qr/ERROR 1198 .*run STOP SLAVE/, 'laufender SQL-Thread: 1198' );
    sh(q{mysql -e "STOP SLAVE SQL_THREAD; SET GLOBAL replica_parallel_threads = 4; START SLAVE SQL_THREAD"});
    is( $M->()->{variables}{slave_parallel_threads}, 4, 'Alias setzt die Variable' );
    like( sh(q{mysql -e "SHOW SLAVE STATUS\G"}), qr/Seconds_Behind_Master: 30$/m, 'holt auf' );
    is( $M->()->{replica}{io}, 'Yes', 'IO-Thread lief weiter' );
}

# --- information_schema.processlist, IN, Zahlvergleiche -------------------------
# Behauptet: information_schema.processlist zeigt die Verbindungen wie SHOW
# PROCESSLIST, mit WHERE (IN, >, IS NULL), ORDER BY und LIMIT.
{
    fresh();
    $M->()->{processlist} = [ { id => 10, user => 'shop', command => 'Sleep', time => 5, count => 2 },
        { id => 20, user => 'deploy', command => 'Query', time => 600, state => 'Waiting for table metadata lock', info => 'ALTER TABLE t ADD c INT' },
        { id => 30, user => 'auswertung', command => 'Sleep', time => 9000 } ];
    is( sh(q{mysql -N -e "SELECT id, user, time FROM information_schema.processlist WHERE command = 'Sleep' AND time > 100"}), "30\tauswertung\t9000", 'Zahlvergleich' );
    is( sh(q{mysql -N -e "SELECT ID FROM information_schema.PROCESSLIST WHERE user IN ('deploy','auswertung') ORDER BY time DESC LIMIT 1"}), '30', 'IN, ORDER BY, LIMIT' );
    is( sh(q{mysql -N -e "SELECT id FROM information_schema.processlist WHERE info IS NOT NULL"}), '20', 'IS NOT NULL' );
    is( sh(q{mysql -N -e "SELECT User FROM mysql.user WHERE User IN ('app','gibtsnicht')"}), "app\napp", 'IN in mysql.user' );
}

# mysqladmin: Optionen mit Wert (-h, -P, -u, -S) sind kein Befehl; Verbindung und Anmeldung
# wie beim Client; ping meldet bei verweigerter Anmeldung trotzdem Erfolg (Server laeuft).
{
    fresh();
    is( sh(q{mysqladmin ping}), 'mysqld is alive', 'ping als root' );
    my ( $o, $ok, $gap ) = sh(q{mysqladmin -h 10.20.0.5 -P 3306 -u app -ppw1 ping});
    ok( !$ok && !$gap, '-h auf andere Adresse bei bind-address 127.0.0.1: kein Erfolg, keine Luecke' );
    is( $o, "mysqladmin: connect to server at '10.20.0.5' failed\nerror: 'Can't connect to server on '10.20.0.5' (115)'", '… Meldung' );
    ( $o, $ok ) = sh(q{mysqladmin -u app -pfalsch ping});
    ok( $ok, 'ping bei verweigerter Anmeldung: Exit 0' );
    like( $o, qr/error: 'Access denied for user 'app'\@'localhost' \(using password: YES\)'/, '… mit Meldung' );
    ( $o, $ok ) = sh(q{mysqladmin -u app -ppw1 status});
    ok( !$ok, 'status bei max_connections ohne SUPER' );
    like( $o, qr/error: 'Too many connections'/, '… Meldung' );
    like( sh(q{mysqladmin -S /run/mysqld/mysqld.sock status}), qr/\AUptime: /, '-S mit Wert' );
}

# SELECT-Listen: Alias (AS oder nachgestellt), Funktionen, COUNT(*) ueber mysql.user,
# SHOW DATABASES LIKE, --connect-timeout; Unbekanntes bleibt eine Luecke.
{
    fresh();
    is( sh(q{mysql -e "SELECT 1 AS ok, 'a b' x"}), "ok\tx\n1\ta b", 'Konstanten mit Alias' );
    is( sh(q{mysql -N -e "SELECT 'tcp ok'"}), 'tcp ok', 'Text mit Leerzeichen ohne Alias' );
    is( sh(q{mysql -N -e "SELECT COUNT(*) FROM mysql.user"}), '3', 'COUNT(*) ueber mysql.user' );
    is( sh(q{mysql -N -e "SELECT CONCAT(user,'@',host) FROM mysql.user WHERE user = 'app'"}), "app\@10.20.0.%\napp\@localhost", 'CONCAT' );
    is( sh(q{mysql -e "SELECT user, CHAR_LENGTH(authentication_string) AS len, LEFT(plugin,5) FROM mysql.user WHERE user = 'root'"}),
        "user\tlen\tLEFT(plugin,5)\nroot\t0\tunix_", 'CHAR_LENGTH mit Alias, LEFT' );
    is( sh(q{mysql -N -e "SELECT PASSWORD('pw1') AS h"}), sh(q{mysql -N -e "SELECT authentication_string FROM mysql.user WHERE user = 'app' AND host = 'localhost'"}),
        'PASSWORD() wie der gespeicherte Hash' );
    is( sh(q{mysql -e "SHOW DATABASES LIKE 'sh%'"}), "Database (sh%)\nshop", 'SHOW DATABASES LIKE' );
    is( sh(q{mysql --connect-timeout=5 -N -e "SELECT 1"}), '1', '--connect-timeout' );
    my ( $o, $ok, $gap ) = sh(q{mysql -e "SELECT SOUNDEX(user) FROM mysql.user"});
    ok( !$ok && $gap, 'unbekannte Funktion: Luecke' );
}

done_testing;
