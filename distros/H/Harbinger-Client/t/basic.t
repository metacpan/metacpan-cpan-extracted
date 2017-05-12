#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Warn;

use Harbinger::Client;

ok(my $cl = Harbinger::Client->new, 'instantiation');
local $ENV{HARBINGER_WARNINGS} = 1;
warning_like { $cl->instant } qr/server can't be blank/, 'no server warns';
warning_like { $cl->instant(server => 'a') } qr/ident can't be blank/, 'no ident warns';
ok(!exception {
   $cl->instant(
      server => "test$$",
      ident => "Never Die/3",
   )
}, 'live with (probably) no server on the other end');

done_testing;
