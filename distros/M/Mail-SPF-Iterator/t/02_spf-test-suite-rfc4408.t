#!/usr/bin/perl
use strict;
use warnings;

require 't/spf-test-suite.pl';
run('t/rfc4408-tests.pl', rfc4408 => 1);
