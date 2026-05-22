#!/usr/bin/env perl
# End-to-end native+TLS test: generates a self-signed cert, runs
# ClickHouse in podman with the native TLS port (9440) enabled, and
# verifies the client can negotiate TLS over the native protocol AND
# run a real query through it.
#
# Activate with TEST_PODMAN_TLS=1. Silently skips otherwise — pulling
# the CH image is large and CI without podman has no chance.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use File::Temp ();
use EV;
use EV::ClickHouse;

plan skip_all => "set TEST_PODMAN_TLS=1 to opt in" unless $ENV{TEST_PODMAN_TLS};

chomp(my $podman  = `which podman 2>/dev/null`);
chomp(my $openssl = `which openssl 2>/dev/null`);
plan skip_all => "podman not in PATH"  unless $podman;
plan skip_all => "openssl not in PATH" unless $openssl;

my $tcp_secure = 19440 + int(rand(1000));   # avoid collisions w/ other tests
my $cname      = "ev_ch_ntls_$$";
my $dir        = File::Temp::tempdir(CLEANUP => 1);
# File::Temp dirs are 0700; container runs as a non-root user that
# needs to traverse + read the bind-mounted contents.
chmod 0755, $dir;

sub run { system(@_) == 0 or die "@_ failed: $?\n" }

# Self-signed server cert for localhost. Use a plain system() check (not
# the die-on-failure run()) so an old openssl that rejects -addext skips
# cleanly instead of aborting with an uncaught exception.
system("openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
    "-subj", "/CN=localhost",
    "-addext", "subjectAltName=DNS:localhost,IP:127.0.0.1",
    "-keyout", "$dir/server.key", "-out", "$dir/server.crt") == 0
    or plan skip_all => "openssl cert generation failed";
# Container runs as a non-root user; mounted key must be world-readable.
chmod 0644, "$dir/server.key";

# CH config: enable tcp_port_secure, disable cleartext native, keep HTTP up.
open my $fh, '>', "$dir/config.xml" or die "open config: $!";
print $fh <<'XML';
<?xml version="1.0"?>
<clickhouse>
  <logger><level>warning</level><console>1</console></logger>
  <!-- Disable the bundled ports we're not testing so we don't fight
       any host process bound to the same numbers via host-network leaks. -->
  <http_port remove="remove"/>
  <tcp_port remove="remove"/>
  <mysql_port remove="remove"/>
  <postgresql_port remove="remove"/>
  <interserver_http_port remove="remove"/>
  <tcp_port_secure>9440</tcp_port_secure>
  <listen_host>0.0.0.0</listen_host>
  <openSSL>
    <server>
      <certificateFile>/etc/ch-tls/server.crt</certificateFile>
      <privateKeyFile>/etc/ch-tls/server.key</privateKeyFile>
      <verificationMode>none</verificationMode>
      <cacheSessions>true</cacheSessions>
      <disableProtocols>sslv2,sslv3</disableProtocols>
      <preferServerCiphers>true</preferServerCiphers>
    </server>
  </openSSL>
</clickhouse>
XML
close $fh;

open my $uh, '>', "$dir/users.xml" or die "open users: $!";
print $uh <<'XML';
<?xml version="1.0"?>
<clickhouse>
  <profiles><default><max_memory_usage>10000000000</max_memory_usage></default></profiles>
  <users>
    <default>
      <password></password>
      <networks><ip>::/0</ip></networks>
      <profile>default</profile>
      <quota>default</quota>
    </default>
  </users>
  <quotas><default><interval><duration>3600</duration></interval></default></quotas>
</clickhouse>
XML
close $uh;

system("$podman rm -f $cname 2>/dev/null");

my $run = "$podman run -d --rm --name $cname".
          " -p $tcp_secure:9440".
          " -v $dir/config.xml:/etc/clickhouse-server/config.d/config.xml:Z".
          " -v $dir/users.xml:/etc/clickhouse-server/users.d/users.xml:Z".
          " -v $dir:/etc/ch-tls:Z".
          " --ulimit nofile=262144:262144".
          " clickhouse/clickhouse-server:latest 2>&1";
my $out = `$run`;
chomp $out;
if ($? != 0) { plan skip_all => "podman run failed: $out" }

# Wait for native+TLS port.
my $deadline = time + 60;
my $ready;
while (time < $deadline) {
    my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $tcp_secure, Timeout => 1);
    if ($s) { $s->close; $ready = 1; last }
    sleep 1;
}
unless ($ready) {
    diag(`$podman logs $cname 2>&1`);
    system("$podman rm -f $cname >/dev/null 2>&1");
    plan skip_all => "ClickHouse native+TLS port never came up";
}
sleep 2;

plan tests => 3;

my ($err, $rows, $rev);
my $ch; $ch = EV::ClickHouse->new(
    host     => '127.0.0.1', port => $tcp_secure, protocol => 'native',
    tls      => 1, tls_skip_verify => 1,
    on_connect => sub {
        $rev = $ch->server_revision;
        $ch->query("select 'hello-native-tls', version()", sub {
            ($rows, $err) = @_; EV::break;
        });
    },
    on_error => sub { $err = $_[0]; EV::break },
);
my $t = EV::timer(15, 0, sub { EV::break }); EV::run; undef $t;

ok !$err, 'native+TLS handshake + query succeeded' or diag "err: $err";
ok $rev && $rev > 0, "negotiated a non-zero server revision ($rev)";
is_deeply $rows && $rows->[0], ['hello-native-tls', $rows->[0][1] // ''],
          'round-tripped a row over native+TLS';

eval { $ch->finish };
system("$podman rm -f $cname >/dev/null 2>&1");
