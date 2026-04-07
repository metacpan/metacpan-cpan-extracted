#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

die "TLS not compiled in\n" unless EV::Redis->has_ssl;

# Configure via environment or edit these defaults:
my $host    = $ENV{REDIS_HOST}    // '127.0.0.1';
my $port    = $ENV{REDIS_PORT}    // 6380;
my $ca      = $ENV{REDIS_TLS_CA} // undef;
my $verify  = defined $ca ? 1 : 0;

my $redis = EV::Redis->new(
    host            => $host,
    port            => $port,
    tls             => 1,
    tls_ca          => $ca,
    tls_verify      => $verify,
    on_error        => sub { warn "Redis error: @_\n" },
    on_connect      => sub { print "TLS connection established\n" },
);

$redis->ping(sub {
    my ($res, $err) = @_;
    die "PING failed: $err\n" if $err;
    print "PONG over TLS: $res\n";

    $redis->info('server', sub {
        my ($info, $err) = @_;
        die "INFO failed: $err\n" if $err;
        my ($ver) = $info =~ /redis_version:(\S+)/;
        print "Server: $ver\n" if $ver;
        $redis->disconnect;
    });
});

EV::run;
