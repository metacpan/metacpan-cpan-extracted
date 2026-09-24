#!/usr/bin/env perl
# TLS and mutual TLS against an etcd started here with throwaway certificates
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use File::Temp 'tempdir';
use IO::Socket::INET;
use POSIX ();

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

sub in_path { my ($cmd) = @_; grep { -x "$_/$cmd" } split /:/, $ENV{PATH} || '' }
plan skip_all => 'etcd and openssl needed in PATH' unless in_path('etcd') && in_path('openssl');

my $dir = tempdir(CLEANUP => 1);

sub quiet {
    my $pid = fork;
    defined $pid or die "fork: $!";
    unless ($pid) {
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        exec @_ or POSIX::_exit(127);
    }
    waitpid $pid, 0;
    return $? == 0;
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "$path: $!";
    print $fh $text;
    close $fh or die "$path: $!";
}

sub make_ca {
    my ($name) = @_;
    write_file("$dir/$name.cnf", <<"CNF");
[req]
distinguished_name = dn
prompt = no
[dn]
CN = $name
[ext]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
CNF
    quiet(qw(openssl req -x509 -newkey rsa:2048 -nodes -days 2 -extensions ext),
        -config => "$dir/$name.cnf", -keyout => "$dir/$name.key", -out => "$dir/$name.crt");
}

sub make_cert {
    my ($name, $ca, $san) = @_;
    write_file("$dir/$name.cnf", <<"CNF");
[req]
distinguished_name = dn
prompt = no
[dn]
CN = $name
[ext]
basicConstraints = CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
${\ ($san ? "subjectAltName = $san" : '') }
CNF
    quiet(qw(openssl req -new -newkey rsa:2048 -nodes),
        -config => "$dir/$name.cnf", -keyout => "$dir/$name.key", -out => "$dir/$name.csr")
    and quiet(qw(openssl x509 -req -days 2 -CAcreateserial -extensions ext),
        -in => "$dir/$name.csr", -CA => "$dir/$ca.crt", -CAkey => "$dir/$ca.key",
        -extfile => "$dir/$name.cnf", -out => "$dir/$name.crt");
}

make_ca('ca') && make_ca('other_ca')
    && make_cert('server', 'ca', 'DNS:localhost') && make_cert('client', 'ca')
    or plan skip_all => 'openssl could not create test certificates';

sub free_port {
    my $s = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0)
        or die "listen: $!";
    return $s->sockport;
}

my ($port, $peer_port) = (free_port(), free_port());
my $etcd_pid = fork;
defined $etcd_pid or die "fork: $!";
unless ($etcd_pid) {
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
    exec 'etcd', '--name', 'tls', '--data-dir', "$dir/data",
        '--listen-client-urls', "https://127.0.0.1:$port",
        '--advertise-client-urls', "https://localhost:$port",
        '--listen-peer-urls', "http://127.0.0.1:$peer_port",
        '--initial-advertise-peer-urls', "http://127.0.0.1:$peer_port",
        '--initial-cluster', "tls=http://127.0.0.1:$peer_port",
        '--cert-file', "$dir/server.crt", '--key-file', "$dir/server.key",
        '--trusted-ca-file', "$dir/ca.crt", '--client-cert-auth'
        or POSIX::_exit(127);
}
END { if ($etcd_pid) { local $?; kill TERM => $etcd_pid; waitpid $etcd_pid, 0 } }

my %mtls = (
    tls_ca_file   => "$dir/ca.crt",
    tls_cert_file => "$dir/client.crt",
    tls_key_file  => "$dir/client.key",
);
my $key = "/test_tls_$$";

sub put_err {
    my (%opt) = @_;
    my $c = EV::Etcd->new(timeout => 3, %opt);
    my $err = 'no callback';
    $c->put($key, 'v', sub { $err = $_[1]; EV::break });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    return $err;
}

my $up;
for (1 .. 50) {
    last if $up = !defined put_err(endpoints => ["localhost:$port"], %mtls);
    select undef, undef, undef, 0.2;
}
plan skip_all => 'TLS etcd did not start' unless $up;

is(put_err(endpoints => ["localhost:$port"], %mtls), undef, 'mutual TLS put');
is(put_err(endpoints => ["https://localhost:$port"], %mtls), undef, 'https:// endpoint');
ok(ref put_err(endpoints => ["127.0.0.1:$port"], %mtls),
    'address missing from the certificate is rejected');
is(put_err(endpoints => ["127.0.0.1:$port"], %mtls, tls_server_name => 'localhost'), undef,
    'tls_server_name checks the certificate against that name');
ok(ref put_err(endpoints => ["localhost:$port"], tls_ca_file => "$dir/ca.crt"),
    'server requiring a client certificate rejects a client without one');
ok(ref put_err(endpoints => ["localhost:$port"], %mtls, tls_ca_file => "$dir/other_ca.crt"),
    'server certificate from an untrusted CA is rejected');
ok(ref put_err(endpoints => ["localhost:$port"]), 'plaintext client cannot talk to a TLS server');

{
    my $c = EV::Etcd->new(endpoints => ["localhost:$port"], %mtls);
    my $value;
    $c->get($key, sub { $value = $_[0] && $_[0]{kvs}[0]{value}; EV::break });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    is($value, 'v', 'value round-trips over TLS');
}

{
    my $dead = free_port();
    my $c = EV::Etcd->new(endpoints => ["https://localhost:$dead", "https://localhost:$port"],
        timeout => 3, %mtls);
    my @errs;
    for (1 .. 2) {
        my $err = 'no callback';
        $c->put($key, 'v', sub { $err = $_[1]; EV::break });
        my $t = EV::timer(5, 0, sub { EV::break });
        EV::run;
        push @errs, $err;
    }
    ok(ref $errs[0], 'dead first TLS endpoint fails');
    is($errs[1], undef, 'failover keeps TLS for the next endpoint');
}

eval { EV::Etcd->new(tls_ca_file => "$dir/missing.crt") };
like($@, qr/cannot open tls_ca_file/, 'missing tls_ca_file croaks');
eval { EV::Etcd->new(tls_cert_file => "$dir/client.crt") };
like($@, qr/must be given together/, 'tls_cert_file without tls_key_file croaks');
eval { EV::Etcd->new(endpoints => ["http://localhost:$port"], tls => 1) };
like($@, qr/http:\/\/ endpoint on a TLS client/, 'http:// endpoint with TLS croaks');

done_testing();
