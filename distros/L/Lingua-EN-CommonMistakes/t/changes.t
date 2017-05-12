#!/usr/bin/env perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval "use Test::CPAN::Changes";
plan skip_all => "Test::CPAN::Changes required for testing Changes" if $@;

changes_ok();
