#!/usr/bin/perl

# Test POD correctness for SMS::AQL
#
# $Id: 2-pod.t 245 2008-02-19 19:27:14Z davidp $

use strict;
use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

