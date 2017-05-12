#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 2 }

use FTN::Address;

my $node = empty FTN::Address(undef);
ok($node->fqdn(), undef);
ok($@, 'Cannot use empty FTN::Address object');

exit;
