#!/usr/bin/env perl

use Test::More tests => 4;

use_ok('IOMux::HTTP');
use_ok('IOMux::HTTP::Client');
use_ok('IOMux::HTTP::Service');
use_ok('IOMux::HTTP::Server');
