use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok('IPC::ConcurrencyLimit') };
BEGIN { use_ok('IPC::ConcurrencyLimit::Lock') };
BEGIN { use_ok('IPC::ConcurrencyLimit::Lock::Flock') };

