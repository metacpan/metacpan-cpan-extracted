#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 2 }

use FTN::Address;

my $node = new FTN::Address(undef);
ok($node, undef);
ok($@, 'Invalid address: <undef>');

exit;
