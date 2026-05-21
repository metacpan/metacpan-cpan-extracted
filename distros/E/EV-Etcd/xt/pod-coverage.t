#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.08; 1"
    or plan skip_all => 'Test::Pod::Coverage 1.08 required';
eval "use Pod::Coverage 0.18; 1"
    or plan skip_all => 'Pod::Coverage 0.18 required';

# Coverage check on EV::Etcd only. The streaming-handle sub-packages
# (EV::Etcd::Watch / Keepalive / Observe) are XS-defined with no .pm of
# their own and only expose cancel + DESTROY — both documented as
# =head3 cancel under their parent service section in lib/EV/Etcd.pm.
# Pod::Coverage can't follow that cross-module reference, so we skip
# them rather than emit false negatives.
pod_coverage_ok(
    'EV::Etcd',
    { trustme => [qr/^txn$/] },   # txn is wrapped in pure-Perl, doc'd via XS path
    'EV::Etcd has POD coverage',
);

done_testing();
