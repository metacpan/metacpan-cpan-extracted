#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use FindBin qw/$Bin/;

BEGIN { use_ok('HTTP::Proxy::Selective') or BAIL_OUT(); }
my $ok = eval {
    require "$Bin/../script/selective_proxy";
};
ok(!$@, 'Can require script') or warn $@;

