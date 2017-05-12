#!/usr/bin/perl

use strict;
use warnings;
use vars qw(@MODULES);

use Test::More;

@MODULES = qw(Env::Export);

eval "use Test::Pod::Coverage 1.00";

plan skip_all =>
    "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
plan tests => scalar(@MODULES);

pod_coverage_ok($_) for (@MODULES);

exit;
