#!/usr/bin/env perl
use strict;
use warnings;
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

my $auth_enabled = 0;
{
    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
    $client->auth_status(sub {
        my ($resp, $err) = @_;
        $auth_enabled = $resp->{enabled} if !$err && $resp;
        EV::break;
    });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
}

if ($auth_enabled) {
    plan skip_all => 'Auth already enabled - cannot run enable/disable tests';
}

plan tests => 10;

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
my $root_password = "root-test-pwd-$$-" . time();
my $auth_token;

# Disable auth again if the run dies between auth_enable and auth_disable
END {
    if ($auth_token && $ENV{ETCD_TEST_AUTH_ENABLE_DISABLE}) {
        my $cleanup_client = EV::Etcd->new(
            endpoints => ['127.0.0.1:2379'],
            auth_token => $auth_token,
        );
        $cleanup_client->auth_disable(sub { EV::break; });
        my $t = EV::timer(5, 0, sub { EV::break });
        EV::run;
    }
}

$client->user_add('root', $root_password, sub {
    my ($resp, $err) = @_;
    ok(!$err, 'root user created');
    diag("Error: " . ($err->{message} // $err)) if $err;
    EV::break;
});
my $t1 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

$client->user_grant_role('root', 'root', sub {
    my ($resp, $err) = @_;
    ok(!$err, 'root role granted');
    diag("Error: " . ($err->{message} // $err)) if $err;
    EV::break;
});
my $t2 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

$client->auth_enable(sub {
    my ($resp, $err) = @_;
    ok(!$err, 'auth_enable succeeded');
    diag("Error: " . ($err->{message} // $err)) if $err;
    EV::break;
});
my $t3 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

$client->authenticate('root', $root_password, sub {
    my ($resp, $err) = @_;
    $auth_token = $resp->{token} if $resp;
    ok($auth_token, 'authenticated and got token');
    diag("Error: " . ($err->{message} // $err)) if $err;
    EV::break;
});
my $t4 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

my $auth_client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
    auth_token => $auth_token,
);

$auth_client->auth_status(sub {
    my ($resp, $err) = @_;
    ok(!$err && $resp->{enabled}, 'auth_status confirms enabled');
    diag("Auth status: enabled=" . ($resp->{enabled} ? "yes" : "no")) if $resp;
    EV::break;
});
my $t5 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

$auth_client->auth_disable(sub {
    my ($resp, $err) = @_;
    ok(!$err, 'auth_disable succeeded');
    ok($resp && $resp->{header}, 'auth_disable has header');
    diag("Error: " . ($err->{message} // $err)) if $err;
    $auth_token = undef if !$err;
    EV::break;
});
my $t6 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

$client->auth_status(sub {
    my ($resp, $err) = @_;
    ok(!$err && !$resp->{enabled}, 'auth_status confirms disabled');
    diag("Auth status: enabled=" . ($resp->{enabled} ? "yes" : "no")) if $resp;
    EV::break;
});
my $t7 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

$client->user_delete('root', sub {
    my ($resp, $err) = @_;
    ok(!$err, 'root user deleted');
    ok($resp && $resp->{header}, 'user_delete has header');
    diag("Error: " . ($err->{message} // $err)) if $err;
    EV::break;
});
my $t8 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

done_testing();
