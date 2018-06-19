#!/usr/bin/env perl
use Test::Pod::Coverage;

all_pod_coverage_ok({also_private => [qr/^BUILD$/]}, '100% POD coverage');

__END__
