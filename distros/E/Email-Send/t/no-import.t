#!perl
use strict;

use lib 't/lib';

use Test::More tests => 3;

BEGIN { use_ok('Email::Send', ()); }

my $message = <<'.';
To: casey@geeknest.com
From: foo@example.com

Blah
.

my $rv = Email::Send::send OK => $message;

ok($rv, "sender reports success");
