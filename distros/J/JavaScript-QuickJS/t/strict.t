#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new();

eval { $js->eval('foo = 123') };

my $err = $@;

like $err, qr<ReferenceError>, 'reference error on undeclared variable';

done_testing;
