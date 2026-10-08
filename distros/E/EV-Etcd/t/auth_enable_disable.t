#!/usr/bin/env perl
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use lib 'blib/lib', 'blib/arch';
use Test::More;

# Toggles auth cluster-wide; a failure mid-run can leave the cluster locked, so
# run it only against a throwaway etcd.

BEGIN {
    unless ($ENV{ETCD_TEST_AUTH_ENABLE_DISABLE}) {
        plan skip_all => 'Set ETCD_TEST_AUTH_ENABLE_DISABLE=1 to run auth enable/disable tests (destructive)';
    }
    eval { require EV };
    plan skip_all => 'EV required' if $@;
}

use EV;
use EV::Etcd;

my $etcd_available = 0;
eval {
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        timeout => 2,
    );
    $client->status(sub {
        my ($resp, $err) = @_;
        $etcd_available = 1 if !$err;
        EV::break;
    });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};

plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $etcd_available;

# Each step waits for its own reply; none at all counts as an error, and a
# late one is ignored rather than ending a later step's wait
sub call {
    my ($client, $method, @args) = @_;
    my ($resp, $err, $done);
    my $live = 1;
    $client->$method(@args, sub {
        return unless $live;
        ($resp, $err) = @_;
        $done = 1;
        EV::break;
    });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $live = 0;
    return $done ? ($resp, $err) : (undef, { status => 'TIMEOUT', message => "$method: no response" });
}

my ($resp, $err) = call(EV::Etcd->new(endpoints => ['127.0.0.1:2379']), 'auth_status');
plan skip_all => 'Auth already enabled - cannot run enable/disable tests'
    if $resp && $resp->{enabled};

plan tests => 18;

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
my $root_password = "root-test-pwd-$$-" . time();
my $auth_on;

# Disable auth again if the run dies while it may be on
END {
    if ($auth_on) {
        my $cleanup_client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
        my (undef, $err) = call($cleanup_client, 'authenticate', 'root', $root_password);
        (undef, $err) = call($cleanup_client, 'auth_disable') unless $err;
        diag("auth may still be enabled: $err->{message}")
            if $err && $err->{status} ne 'FAILED_PRECONDITION';
    }
}

($resp, $err) = call($client, 'user_add', 'root', $root_password);
ok(!$err, 'root user created') or diag explain $err;
($resp, $err) = call($client, 'user_grant_role', 'root', 'root');
ok(!$err, 'root role granted') or diag explain $err;
$auth_on = 1;
($resp, $err) = call($client, 'auth_enable');
ok(!$err, 'auth_enable succeeded') or diag explain $err;
($resp, $err) = call($client, 'authenticate', 'root', $root_password);
my $auth_token = $resp && $resp->{token};
ok($auth_token, 'authenticated and got token') or diag explain $err;

my $auth_client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
    auth_token => $auth_token,
);
($resp, $err) = call($auth_client, 'auth_status');
ok($resp && $resp->{enabled}, 'auth_status confirms enabled') or diag explain $err;

# Stream leader metadata must coexist with the saved authentication token.
($resp) = call($auth_client, 'lease_grant', 30);
my $lease = $resp && $resp->{id};
my (%ready, %errors, @handles);
if ($lease) {
    my $election = "/test-auth-streams-$$";
    call($auth_client, 'election_campaign', $election, $lease, 'leader');
    my $stream_callback = sub {
        my $name = shift;
        return sub {
            if ($_[1]) { $errors{$name} = $_[1] }
            else { $ready{$name} = 1 }
            EV::break if keys(%ready) + keys(%errors) == 3;
        };
    };
    push @handles, $auth_client->watch($election, $stream_callback->('watch'));
    push @handles, $auth_client->lease_keepalive($lease, $stream_callback->('keepalive'));
    push @handles, $auth_client->election_observe($election, $stream_callback->('observe'));
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
}
for my $name (qw(watch keepalive observe)) {
    ok($ready{$name} && !$errors{$name}, "authenticated $name receives responses");
    diag explain $errors{$name} if $errors{$name};
}
$_->cancel(sub {}) for @handles;
call($auth_client, 'lease_revoke', $lease) if $lease;

($resp, $err) = call($auth_client, 'auth_disable');
ok(!$err, 'auth_disable succeeded') or diag explain $err;
ok($resp && $resp->{header}, 'auth_disable has header');
$auth_on = 0 unless $err;

# etcd before 3.4.28/3.5.10 keeps rejecting $client's token: the failure must drop it
($resp, $err) = call($client, 'authenticate', 'root', $root_password);
is($err && $err->{status}, 'FAILED_PRECONDITION', 'authenticate fails once auth is disabled');

# Disabling auth wiped the old simple token on every version: a client still
# sending it is refused as "invalid auth token" once auth is back on
$auth_on = 1;
($resp, $err) = call($client, 'auth_enable');
ok(!$err, 'auth re-enabled') or diag explain $err;
($resp, $err) = call($client, 'get', '/test-auth-dropped-token');
is($err && $err->{message}, 'etcdserver: user name is empty', 'the dropped token is not sent');
($resp, $err) = call($client, 'authenticate', 'root', $root_password);
ok($resp && $resp->{token}, 're-authenticated') or diag explain $err;
($resp, $err) = call($client, 'auth_disable');
ok(!$err, 'auth disabled again') or diag explain $err;
$auth_on = 0 unless $err;

($resp, $err) = call($client, 'auth_status');
ok($resp && !$resp->{enabled}, 'auth_status confirms disabled') or diag explain $err;
($resp, $err) = call($client, 'user_delete', 'root');
ok(!$err, 'root user deleted') or diag explain $err;
ok($resp && $resp->{header}, 'user_delete has header');
