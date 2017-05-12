#!/usr/bin/perl

###########################################################################
# This tests the basic functionality of Froody::Response::XML
###########################################################################

use strict;
use warnings;

# start the tests
use Test::More tests => 4;
use Test::Exception;
use Test::Exception;

use Froody::Response::Error;
use Froody::Response::String;
use Froody::Response::XML;

{ local $TODO = "Make this pretty, not evil, like it is now.";
throws_ok {
  Froody::Response::String ->new()
                           ->set_string("Mr Katz.  He dead.")
                           ->as_error;
} qr/froody.xml.parse/;
isa_ok $@, "Froody::Error";

throws_ok {
  Froody::Response::String ->new()
                           ->set_string("<rsp></rsp>")
                           ->as_error;
} qr/froody.xml.parse/;
}
isa_ok $@, "Froody::Error";
