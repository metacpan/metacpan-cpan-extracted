#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Fatal;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new();
my $date = $js->eval('new Date()');

my $err = exception {
    $date->toLocaleString(\*STDOUT);
};

like($err, qr<GLOB>);

done_testing;
