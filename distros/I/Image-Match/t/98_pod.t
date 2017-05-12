#! /usr/bin/perl
# $Id: 98_pod.t,v 1.1 2008/09/01 09:26:28 dk Exp $

use strict;
use warnings;

use Test::More;
eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;
all_pod_files_ok(all_pod_files('blib'));
