#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.08; 1"
    or plan skip_all => 'Test::Pod::Coverage 1.08 required';
eval "use Pod::Coverage 0.18; 1"
    or plan skip_all => 'Pod::Coverage 0.18 required';

# EV::Etcd only: the XS handle packages (Watch, Keepalive, Observe) have cancel
# documented in lib/EV/Etcd.pm, which Pod::Coverage cannot follow
pod_coverage_ok(
    'EV::Etcd',
    { trustme => [qr/^txn$/] },   # txn is wrapped in pure-Perl, doc'd via XS path
    'EV::Etcd has POD coverage',
);

done_testing();
