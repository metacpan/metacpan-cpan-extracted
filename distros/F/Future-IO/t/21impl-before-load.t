#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

no warnings 'once';
$Future::IO::IMPL = "TestImplementation";
require Future::IO;

{
   package TestImplementation;
   sub sleep { return "TestFuture" }
}

is( Future::IO->sleep(123), "TestFuture", 'override before require still works' );

done_testing;
