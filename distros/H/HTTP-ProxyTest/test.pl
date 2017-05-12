#!/usr/bin/env perl -w
#
# $Id: test.pl,v 1.1.1.1 2010/07/14 02:57:49 gunnarh Exp $

use strict;
use Test;
BEGIN { plan tests => 2 }

#1 loads?
use HTTP::ProxyTest;
ok(1);

#2 runs error free without arguments?
$ENV{REMOTE_ADDR} ||= '127.0.0.1';
proxytest();
ok(1);

