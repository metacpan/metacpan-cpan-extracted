#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

no warnings 'once';
$Future::IO::IMPL = "TestImplementation";
require Future::IO;

{
   package TestImplementation;
   sub sleep { return "TestFuture" }
}

is( Future::IO->sleep(123), "TestFuture", 'override before require still works' );

done_testing;
