#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new();

eval { $js->eval('[BigInt(123)]') };
my $err = $@;
like($err, qr<big\s*int>i, 'BigInt in array');

eval { $js->eval('let foo = { foo: BigInt(123) }; foo') };
$err = $@;
like($err, qr<big\s*int>i, 'BigInt in plain object');

done_testing;
