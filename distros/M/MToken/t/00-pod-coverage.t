#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <abalama@cpan.org>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 00-pod-coverage.t 44 2017-07-31 14:44:24Z minus $
#
#########################################################################
use strict;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $ver = 1.08;
eval "use Test::Pod::Coverage $ver";
plan skip_all => "Test::Pod::Coverage $ver required for testing POD coverage" if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $verpc = 0.18;
eval "use Pod::Coverage $verpc";
plan skip_all => "Pod::Coverage $verpc required for testing POD coverage" if $@;

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";

my %skip = (
    trustme => [
        qr/^sec_[a-z]+$/,
        qr/^[A-Z_]+$/,
    ],
  );
all_pod_coverage_ok(\%skip);

1;
__END__
