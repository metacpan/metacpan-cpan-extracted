#!perl -w

use Test::More tests => 1;

use IPC::Run3;
use strict;

local $SIG{__DIE__} = sub { ok(0, '__DIE__ handler should not be called'); };

my ( $in, $out, $err );

ok(run3 [$^X, '-e1' ], $in, $out, $err);

