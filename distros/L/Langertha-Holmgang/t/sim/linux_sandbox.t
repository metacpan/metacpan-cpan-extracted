#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use Langertha::Holmgang::Simulators;
use Langertha::Holmgang::Sim::Linux;

# Linux-Simulator mit Sandbox (ADR 0011): Ein echtes Programm ohne Nachbildung
# (python3 -c, ein awk-Skript jenseits der Filter) ist ohne Sandbox eine Luecke.
# Mit einer Sandbox im Kontext laeuft genau dieser Befehl dort; Ausgabe, Status
# und geaenderte Dateien kommen in den Zustand. Behauptet wird: ohne Sandbox
# aendert sich nichts; was nur die Simulation weiss, geht nie hinaus; eine
# Sandbox, die nicht antwortet, laesst die Luecke stehen.
# Die Sandbox hier ist eine Attrappe — kein Docker, kein Netz.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

{
  package Fake::Sandbox;
  sub new { my ( $c, %o ) = @_; return bless { calls => [], %o }, $c }
  sub run {
    my ( $self, %a ) = @_;
    push @{ $self->{calls} }, \%a;
    return $self->{answer}->(%a);
  }
}

sub world {
  return {
    srv => {
      type  => 'linux',
      users => { app => { uid => 1001, groups => ['app'] } },
      groups => { app => { gid => 1001 } },
      files => {
        '/etc/app.conf'        => "debug = on\n",
        '/srv/app/data.json'   => { content => qq({"n": 3}\n), owner => 'app', group => 'app', mode => '0640' },
        '/srv/app/current'     => { link => 'releases/1' },
        '/var/log/app/big.log' => { size => '36G', content => '', open_by => 'app' },
        '/opt/tool/report.py'  => { content => "#!/usr/bin/env python3\nprint('bericht')\n", mode => '0755' },
        '/opt/tool/sync.py'    => { content => "#!/usr/bin/env python3\nimport subprocess\nsubprocess.run(['systemctl','restart','app'])\n", mode => '0755' },
      },
      services => { app => { active => 1 } },
    },
  };
}

sub sims { my ($sb) = @_; return Langertha::Holmgang::Simulators->new( $sb ? ( sandbox => $sb ) : () ) }
my $ok_answer = sub { my (%a) = @_; return { output => "aus der Sandbox\n", exit => 0, changed => {}, deleted => [] } };

# --- ohne Sandbox: die Luecke wie bisher ----------------------------------------------
{
  my $s = world();
  my ( $o, $ok, $gap ) = sims()->run_command( $s, 'srv', q{python3 -c 'print(1)'} );
  is( $o, '', 'ohne Sandbox: neutrale Antwort' );
  ok( !$ok, 'ohne Sandbox: gescheitert' );
  like( $gap, qr/\Apython3 -c/, 'ohne Sandbox: als Luecke vermerkt' );
}

# --- mit Sandbox: der Befehl laeuft dort ------------------------------------------------
{
  my $s  = world();
  my $sb = Fake::Sandbox->new( answer => $ok_answer );
  my ( $o, $ok, $gap ) = sims($sb)->run_command( $s, 'srv', q{python3 -c 'print(open("/etc/app.conf").read())'} );
  is( $o, 'aus der Sandbox', 'Ausgabe der Sandbox, ohne den letzten Zeilenumbruch' );
  ok( $ok, 'Status 0 gelingt' );
  ok( !defined $gap, 'keine Luecke' );
  my $c = $sb->{calls}[0];
  is_deeply( $c->{argv}, [ 'python3', '-c', 'print(open("/etc/app.conf").read())' ], 'argv ohne Shell, Quotes aufgeloest' );
  is( $c->{host}, 'srv', 'Hostname des Geraets' );
  is( $c->{cwd}, '/root', 'Verzeichnis der Shell' );
  is( $c->{now}, Langertha::Holmgang::Sim::Linux::_sim_now(), 'Uhr der Simulation' );
  is( $c->{files}{'/etc/app.conf'}{content}, "debug = on\n", 'Datei des Zustands geht mit' );
  is_deeply( [ @{ $c->{files}{'/srv/app/data.json'} }{qw( mode uid gid )} ], [ 0640, 1001, 1001 ], 'Rechte und Eigentuemer als Zahlen' );
  is( $c->{files}{'/srv/app/current'}{link}, 'releases/1', 'Symlink als Symlink' );
  ok( !exists $c->{files}{'/var/log/app/big.log'}, 'Datei, die der Zustand nur beschreibt (36G), geht nicht mit' );
}

# --- Pipe und Eingabe: die Shell bleibt die der Simulation -------------------------------
{
  my $s  = world();
  my $sb = Fake::Sandbox->new( answer => sub { my (%a) = @_; return { output => uc( $a{stdin} // '' ), exit => 0, changed => {}, deleted => [] } } );
  my ( $o, $ok, $gap ) = sims($sb)->run_command( $s, 'srv', q{cat /etc/app.conf | python3 -c 'import sys; print(sys.stdin.read())' | grep DEBUG} );
  is( $o, 'DEBUG = ON', 'Eingabe aus der Pipe, Ausgabe weiter durch den Filter der Simulation' );
  ok( !defined $gap, 'keine Luecke' );
  is( scalar @{ $sb->{calls} }, 1, 'nur das eine Programm lief in der Sandbox' );
}

# --- Status und Dateien kommen zurueck ---------------------------------------------------
{
  my $s  = world();
  my $sb = Fake::Sandbox->new( answer => sub {
    return { output => "Traceback\n", exit => 3, deleted => ['/etc/app.conf'],
      changed => {
        '/srv/app/data.json' => { content => qq({"n": 4}\n), mode => 0640 },
        '/tmp/neu.txt'       => { content => "neu\n", mode => 0644, new => 1 },
        '/usr/local/bin/x'   => { content => "#!/bin/sh\n", mode => 0755, new => 1 },
        '/srv/app/__pycache__/m.cpython-311.pyc' => { content => 'x', mode => 0644, new => 1 },
      } };
  } );
  my $sims = sims($sb);
  my ( $o, $ok, $gap, $exit ) = $sims->run_command( $s, 'srv', q{python3 -c 'pass'} );
  ok( !$ok, 'Status ungleich 0 scheitert' );
  is( $exit, 3, 'der Exit-Status des Programms' );
  is( $o, 'Traceback', 'Ausgabe auch beim Scheitern' );
  my $f = $s->{srv}{files};
  is( $f->{'/srv/app/data.json'}{content}, qq({"n": 4}\n), 'geaenderter Inhalt im Zustand' );
  is( $f->{'/srv/app/data.json'}{owner}, 'app', 'Eigentuemer bleibt' );
  is( $f->{'/tmp/neu.txt'}, "neu\n", 'neue Datei' );
  is( $f->{'/usr/local/bin/x'}{mode}, '0755', 'neue Datei mit ihren Rechten' );
  ok( !exists $f->{'/etc/app.conf'}, 'geloeschte Datei ist weg' );
  ok( !grep( {/__pycache__/} keys %$f ), '__pycache__ kommt nicht in den Zustand' );
  ( $o ) = $sims->run_command( $s, 'srv', 'cat /tmp/neu.txt; ls -l /usr/local/bin/x' );
  like( $o, qr/\Aneu\n-rwxr-xr-x/, 'die Simulation liest, was die Sandbox schrieb' );
}

# --- was nur die Simulation weiss, geht nicht hinaus --------------------------------------
for my $t (
  [ q{python3 -c 'import subprocess; subprocess.run(["systemctl","stop","app"])'}, 'anderer Prozess (subprocess)' ],
  [ q{python3 -c 'import os; os.system("reboot")'},                             'os.system' ],
  [ q{perl -e 'print `systemctl is-active app`'},                                 'Backticks in perl' ],
  [ q{python3 -c 'import socket; socket.create_connection(("db1",5432))'},        'Netz' ],
  [ q{python3 -c 'print(open("/proc/meminfo").read())'},                           '/proc' ],
  [ q{python3 -c 'import os; print(os.path.getsize("/var/log/app/big.log"))'},     'Datei, die der Zustand nur beschreibt' ],
  [ q{python3 -c 'import os; print(os.listdir("/var/log"))'},                      'Verzeichnis ueber einer solchen Datei' ],
  [ q{python3 -c 'print(open("/etc/passwd").read())'},                             'Konten, die nicht als Datei im Zustand liegen' ],
  [ q{awk 'BEGIN { system("systemctl restart app") }'},                            'system() in awk' ],
  [ q{sudo -u app python3 -c 'print(1)'},                                          'als anderer Benutzer' ],
  [ q{/opt/tool/sync.py},                                                          'Skript aus dem Zustand, das Prozesse startet' ],
  [ q{openssl s_client -connect 127.0.0.1:443},                                    'openssl spricht mit einem Dienst' ],
  [ q{top},                                                                        'interaktives Programm' ],
) {
  my $s  = world();
  my $sb = Fake::Sandbox->new( answer => $ok_answer );
  my ( $o, $ok, $gap ) = sims($sb)->run_command( $s, 'srv', $t->[0] );
  is( scalar @{ $sb->{calls} }, 0, 'bleibt in der Simulation: '.$t->[1] );
  ok( defined $gap, '… und bleibt eine Luecke' );
}

# --- Skript aus dem Zustand mit Interpreter aus der Liste -----------------------------------
{
  my $s  = world();
  my $sb = Fake::Sandbox->new( answer => $ok_answer );
  my ( $o, $ok, $gap ) = sims($sb)->run_command( $s, 'srv', '/opt/tool/report.py --kurz' );
  is_deeply( $sb->{calls}[0]{argv}, [ '/opt/tool/report.py', '--kurz' ], 'Python-Skript des Geraets laeuft in der Sandbox' );
  ok( !defined $gap, 'keine Luecke' );
}

# --- was die Simulation nachbildet, bleibt bei ihr ------------------------------------------
{
  my $s  = world();
  my $sb = Fake::Sandbox->new( answer => $ok_answer );
  my ( $o, $ok, $gap ) = sims($sb)->run_command( $s, 'srv', 'systemctl is-active app; cat /etc/app.conf; echo x | grep x; head -n 1 /etc/app.conf' );
  is( scalar @{ $sb->{calls} }, 0, 'nachgebildete Befehle laufen nie in der Sandbox' );
  like( $o, qr/\Aactive\ndebug = on\nx\ndebug = on\z/, '… und antworten wie immer' );
}

# --- eine Sandbox, die nicht antwortet: die Luecke bleibt ------------------------------------
{
  my $s  = world();
  my $sb = Fake::Sandbox->new( answer => sub { return ( undef, 'node is not in the image' ) } );
  my ( $o, $ok, $gap ) = sims($sb)->run_command( $s, 'srv', q{python3 -c 'print(1)'} );
  is( $o, '', 'keine geratene Antwort' );
  ok( !$ok, 'gescheitert' );
  like( $gap, qr/\Apython3 -c/, 'als Luecke vermerkt' );
}

done_testing;
