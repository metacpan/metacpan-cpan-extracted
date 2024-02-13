#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Fatal;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new();
my $func = $js->eval('() => 123');

my $err = exception {
    $func->call(\*STDOUT);
};

like($err, qr<GLOB>);

done_testing;

