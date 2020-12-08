#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

BEGIN { use_ok('HEAT::Crypto', qw(keygen priv_to_pub_key shared_key sign verify
		encrypt decrypt)) }

ok(my $u1 = keygen(), 'keygen u1');
ok(my $u2 = keygen(), 'keygen u2');
is($u1->{p}, priv_to_pub_key($u1->{k}), 'priv to pub key u1');
is($u2->{p}, priv_to_pub_key($u2->{k}), 'priv to pub key u2');

is(shared_key($u1->{k}, $u2->{p}), shared_key($u2->{k}, $u1->{p}), 'shared key');
ok(my $s = sign($u1->{k}, 'OK'), 'sign');

ok(verify($s, 'OK', $u1->{p}), 'verify');

ok(my $e = encrypt('OK', $u1->{k}), 'encrypt');
is(decrypt($e, $u1->{k}), 'OK', 'decrypt');

ok($e = encrypt('OK', $u1->{k}, $u2->{p}), 'encrypt shared');
is(decrypt($e, $u2->{k}, $u1->{p}), 'OK', 'decrypt shared');
