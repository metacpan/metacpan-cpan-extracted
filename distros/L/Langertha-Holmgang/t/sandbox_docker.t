#!/usr/bin/env perl
# Langertha::Holmgang::Sandbox::Docker against a real container runtime
# (ADR 0011). Opt-in: the tests of this distribution are network-free and need
# no service, so this one runs only with HOLMGANG_SANDBOX_DOCKER=1 (or the
# runtime's name) and the image of share/sandbox/Dockerfile built:
#
#   docker build -t langertha-holmgang-sandbox:1 share/sandbox
#   HOLMGANG_SANDBOX_DOCKER=1 prove -l t/sandbox_docker.t
#
# Claimed: the program sees exactly the files handed over, the simulation's
# clock and host name, and no network; output, exit status, changed, new and
# removed files come back; a program missing from the image, a timeout and an
# image that is not there give no guessed answer.
use strict;
use warnings;
use utf8;
use Test::More;

use Langertha::Holmgang::Sandbox::Docker;
use Langertha::Holmgang::Simulators;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

my $rt = $ENV{HOLMGANG_SANDBOX_DOCKER};
plan skip_all => 'set HOLMGANG_SANDBOX_DOCKER=1 to test against a container runtime' unless $rt;
my $sb = Langertha::Holmgang::Sandbox::Docker->new( docker => [ $rt eq '1' ? 'docker' : $rt ],
  ( $ENV{HOLMGANG_SANDBOX_IMAGE} ? ( image => $ENV{HOLMGANG_SANDBOX_IMAGE} ) : () ) );
my ( $there, $id ) = $sb->available;
plan skip_all => 'the sandbox is not available: '.$id unless $there;
like( $id, qr/\Asha256:[0-9a-f]{64}\z/, 'available names the image id' );

my $NOW = 1792490400;    # 2026-10-20 12:00 CEST
my %world = (
  files => {
    '/etc/app.conf'             => { content => "debug = on\nname = größe\n", mode => 0640, uid => 1001, gid => 1001 },
    '/etc/hosts'                => { content => "127.0.0.1 localhost\n192.0.2.7 db1\n" },
    '/srv/app/current'          => { link => 'releases/1' },
    '/srv/app/releases/1/x.txt' => { content => "eins\n" },
  },
  dirs => { '/srv/app/leer' => { mode => 0750 } },
  now  => $NOW, host => 'app1',
);

# what the program sees and what comes back
{
  my ( $r, $why ) = $sb->run( %world, stdin => "a\nb\n", argv => [ 'python3', '-c', <<'PY' ] );
import sys, os, datetime, socket
print(open("/etc/app.conf").read().upper(), end="")
print(datetime.datetime.now().strftime("%Y-%m-%d %H:%M"), socket.gethostname(), os.getcwd())
print(oct(os.stat("/etc/app.conf").st_mode & 0o777), os.stat("/etc/app.conf").st_uid, os.path.isdir("/srv/app/leer"))
print(open("/srv/app/current/x.txt").read().strip(), open("/etc/hosts").read().split()[-1], len(sys.stdin.read().split()))
print("to stderr", file=sys.stderr)
open("/etc/app.conf", "a").write("x = 1\n")
open("/tmp/neu", "w").write("n")
os.chmod("/tmp/neu", 0o600)
os.remove("/srv/app/releases/1/x.txt")
os.symlink("releases/2", "/srv/app/next")
sys.exit(3)
PY
  ok( $r, 'the program ran' ) or diag $why;
  is( $r->{exit}, 3, 'its exit status' );
  is( $r->{output}, "DEBUG = ON\nNAME = GRÖSSE\n2026-10-20 12:00 app1 /root\n0o640 1001 True\neins db1 2\nto stderr\n",
    'files with mode and owner, a symlink, a directory, /etc/hosts, stdin, the simulation\'s clock, host name, cwd; stderr in the output' );
  is( $r->{clock}, 'sim', 'the clock is the simulation\'s' );
  is_deeply( $r->{changed}, {
      '/etc/app.conf' => { content => "debug = on\nname = größe\nx = 1\n", mode => 0640 },
      '/tmp/neu'      => { content => 'n', mode => 0600, new => 1 },
      '/srv/app/next' => { link => 'releases/2' },
    }, 'changed and new files, with mode; untouched files are not named' );
  is_deeply( $r->{deleted}, ['/srv/app/releases/1/x.txt'], 'the removed file' );
  is( scalar @{ $sb->log }, 1, 'the call is logged' );
  is( ( $sb->take_log )[0]{exit}, 3, '... with its exit status' );
}

# no network, no host
{
  my ( $r ) = $sb->run( %world, argv => [ 'python3', '-c', <<'PY' ] );
import socket, os
try:
    socket.create_connection(("192.0.2.1", 80), 2); print("connected")
except OSError as e:
    print("no network")
print(sorted(os.listdir("/home")), os.path.exists("/var/run/docker.sock"))
PY
  is( $r->{output}, "no network\n[] False\n", 'no network, nothing of the host' );
}

# a second call starts from what the caller hands over, not from the first
{
  my ( $r ) = $sb->run( %world, argv => [ 'sh', '-c', 'ls /tmp/neu 2>&1; cat /srv/app/releases/1/x.txt' ] );
  like( $r->{output}, qr/No such file.*\neins\n\z/s, 'every call is a fresh container' );
}

# not usable: no guessed answer
{
  my ( $r, $why ) = $sb->run( %world, argv => [ 'node', '-v' ] );
  ok( !$r, 'a program that is not in the image gives no result' );
  is( $why, 'node is not in the image', '... and the reason' );
  my $fast = Langertha::Holmgang::Sandbox::Docker->new( docker => $sb->docker, image => $sb->image, timeout => 2 );
  ( $r ) = $fast->run( %world, argv => [ 'python3', '-c', 'import time; time.sleep(60)' ] );
  is( $r->{exit}, 124, 'past the timeout the program is killed: exit 124' );
  my $none = Langertha::Holmgang::Sandbox::Docker->new( docker => $sb->docker, image => 'langertha-holmgang-sandbox:no-such-tag' );
  my ( $ok, $reason ) = $none->available;
  ok( !$ok, 'an image that is not there is not available' );
  like( $reason, qr/is not there/, '... and says so' );
  ( $r, $why ) = $none->run( %world, argv => ['true'] );
  ok( !$r, '... and a run on it gives no result' );
}

# through the Linux simulator: the real program instead of the gap
{
  my $state = { h => { type => 'linux', files => { '/srv/app/data.json' => qq({"n": 3}\n) } } };
  my $sims  = Langertha::Holmgang::Simulators->new( sandbox => $sb );
  my ( $o, $ok, $gap ) = $sims->run_command( $state, 'h',
    q{python3 -c 'import json; p="/srv/app/data.json"; d=json.load(open(p)); d["n"]+=1; json.dump(d,open(p,"w")); print(d["n"])' && cat /srv/app/data.json | python3 -c 'import sys,json; print(json.load(sys.stdin)["n"] * 10)'} );
  is( $o, "4\n40", 'python writes a file of the device, the simulated cat reads it, python reads the pipe' );
  ok( $ok && !defined $gap, 'succeeded, no gap' );
  is( $state->{h}{files}{'/srv/app/data.json'}, '{"n": 4}', 'the state carries the change' );
  ( $o, $ok, $gap ) = $sims->run_command( $state, 'h', q{python3 --version} );
  like( $o, qr/\APython 3\.\d+/, 'a version query answers' );
}

done_testing;
