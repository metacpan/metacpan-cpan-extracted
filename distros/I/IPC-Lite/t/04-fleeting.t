# -*- perl -*-

# t/04-fleeting.t - check to see if ttl works

use strict;
use warnings;
use Test::Simple tests=>2;

BEGIN {
	(-d 'tmp') || mkdir('tmp') || die;
}

use IPC::Lite Path=>'tmp/test.db', TTL=>1, qw($tmp);

$tmp = "fleeting";
ok($tmp eq 'fleeting', "here: $tmp");

sleep(2);

IPC::Lite::cleanup();

no warnings 'uninitialized';
ok(! defined $tmp, "gone: $tmp");
