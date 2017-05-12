#!/usr/bin/perl
# $Id: 04-pod.t 2 2006-05-02 11:15:26Z roel $
use strict;
use warnings;
use Test::More;
eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;
all_pod_files_ok();

__END__
