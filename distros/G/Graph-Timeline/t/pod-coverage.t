#!/usr/bin/perl

# $Id: pod-coverage.t,v 1.1 2005/09/13 21:12:34 peterhickman Exp $

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan( 'skip_all' => 'Test::Pod::Coverage 1.04 required for testing POD' ) if $@;

all_pod_coverage_ok();

# vim: syntax=perl :
