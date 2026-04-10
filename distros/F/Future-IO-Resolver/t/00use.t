#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;

require Future::IO::Resolver;

require Future::IO::Resolver::Using::LibAsyncNS;
require Future::IO::Resolver::Using::Socket;

pass "Modules loaded";
done_testing;
