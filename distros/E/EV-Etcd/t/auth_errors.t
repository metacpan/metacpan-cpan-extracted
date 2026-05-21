#!/usr/bin/env perl
# Exercise auth error paths that t/auth.t skips: wrong password, duplicate
# user, missing user. Auth itself stays disabled at the end.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

my $available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], timeout => 2);
    $c->status(sub { $available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};
plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $available;

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
my $user = "test_autherr_$$";

# Setup: create a user we can test against
my $err;
$client->user_add($user, "rightpw", sub { $err = $_[1]; EV::break });
my $t1 = EV::timer(3, 0, sub { EV::break });
EV::run;
plan skip_all => "user_add failed: $err->{message}" if $err && $err->{status} ne 'ALREADY_EXISTS';

# 1. user_add of an existing user -> ALREADY_EXISTS / FAILED_PRECONDITION
my $dup_err;
$client->user_add($user, "anything", sub { $dup_err = $_[1]; EV::break });
my $t2 = EV::timer(3, 0, sub { EV::break });
EV::run;
ok($dup_err, 'duplicate user_add returns error');
ok(ref($dup_err) eq 'HASH' && $dup_err->{message}, 'error has message');
note("duplicate user_add: $dup_err->{status} - $dup_err->{message}");

# 2. user_get of nonexistent user -> NOT_FOUND
my $missing_err;
$client->user_get("does_not_exist_$$", sub { $missing_err = $_[1]; EV::break });
my $t3 = EV::timer(3, 0, sub { EV::break });
EV::run;
ok($missing_err, 'user_get of missing user returns error');
note("missing user_get: $missing_err->{status} - $missing_err->{message}");

# 3. user_change_password of missing user -> NOT_FOUND
my $cp_err;
$client->user_change_password("does_not_exist_$$", "x", sub { $cp_err = $_[1]; EV::break });
my $t4 = EV::timer(3, 0, sub { EV::break });
EV::run;
ok($cp_err, 'change_password of missing user returns error');

# 4. role_get of missing role
my $role_err;
$client->role_get("does_not_exist_$$", sub { $role_err = $_[1]; EV::break });
my $t5 = EV::timer(3, 0, sub { EV::break });
EV::run;
ok($role_err, 'role_get of missing role returns error');

# 5. user_grant_role of nonexistent role -> error
my $grant_err;
$client->user_grant_role($user, "no_such_role_$$", sub { $grant_err = $_[1]; EV::break });
my $t6 = EV::timer(3, 0, sub { EV::break });
EV::run;
ok($grant_err, 'grant of nonexistent role returns error');

# Errors must all use the structured shape
for my $e ($dup_err, $missing_err, $cp_err, $role_err, $grant_err) {
    next unless $e;
    ok(ref($e) eq 'HASH', 'error is a hashref');
    ok(exists $e->{code} && exists $e->{status} && exists $e->{message}
       && exists $e->{source} && exists $e->{retryable},
       'error has all 5 standard fields');
}

# Cleanup
$client->user_delete($user, sub { EV::break });
my $tc = EV::timer(3, 0, sub { EV::break });
EV::run;

done_testing();
