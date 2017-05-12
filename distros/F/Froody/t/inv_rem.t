#!/usr/bin/perl

#################################################################
# tests remote invokation (i.e. Froody::Invoker::Remote)
#################################################################

use strict;
use warnings;

# start the tests
use Test::More tests => 2;
use Test::Exception;

use Froody::Method;
use Froody::Invoker::Remote;

# from a local server
my $invoker = Froody::Invoker::Remote
              ->new()
              ->url("http://localhost:1/");
              
my $method = Froody::Method
              ->new()
              ->full_name("does.it.hurt")
              ->invoker($invoker);

throws_ok {

 my $rsp = $method->call({});
} qr/Bad response from remote server/, "got the correct error back!";

is $method->source, 'http://localhost:1/: does.it.hurt',
  "Method source looks right.";

#We actually handle the rest of the success and failure conditions in t/high-level.t
