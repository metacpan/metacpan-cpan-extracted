#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

use_ok('Maypole::Constants');
ok($Maypole::Constants::VERSION, 'defines $VERSION');
is(\&OK, \&Maypole::Constants::OK, 'exports OK');
is(OK(), 0, 'OK correctly defined');
is(\&ERROR, \&Maypole::Constants::ERROR, 'exports ERROR');
is(ERROR(), 500, 'ERROR correctly defined');
is(\&DECLINED, \&Maypole::Constants::DECLINED, 'exports DECLINED');
is(DECLINED(), -1, 'DECLINED correctly defined');
