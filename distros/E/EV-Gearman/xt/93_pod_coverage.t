#!/usr/bin/env perl
# Author test: every public method has POD. Underscore-prefixed subs
# (_submit_internal, _register_function, _buf_caps, ...) are internal
# and intentionally undocumented.
use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => 'Test::Pod::Coverage 1.08 required' if $@;

my %also_private = ( also_private => [ qr/^_/ ] );

plan tests => 2;
pod_coverage_ok('EV::Gearman',       \%also_private, 'EV::Gearman POD covers all public methods');
pod_coverage_ok('EV::Gearman::Job',  \%also_private, 'EV::Gearman::Job POD covers all public methods');
