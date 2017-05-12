#!/usr/bin/perl

###########################################################################
# This tests the basic functionality of Froody::Response and
# Froody::Response::String.
#
# It's the only rsp_*.t that tests the underlying features that all the
# Froody::Response objects have - e.g. testing the cookies
#
# It does not feature conversion tests;  Those are in rsp_convert.t
###########################################################################

use strict;
use warnings;

use Test::Exception;

# start the tests
use Test::More tests => 16;

use_ok("Froody::Response");
use_ok("Froody::Response::String");
use_ok("Froody::Method");

#####
# test the basic string stuff

{
my $frs = Froody::Response::String->new();
isa_ok($frs,"Froody::Response", "got a froody response back");
$frs->set_string( <<ENDOFRSP );
<rsp stat="ok">
  <monger>L\x{e9}on Brocard</monger>
</rsp>
ENDOFRSP

is($frs->render, <<ENDOFEXPECTED, "got expected output back");
<?xml version="1.0" encoding="utf-8" ?>
<rsp stat="ok">
  <monger>L\x{c3}\x{a9}on Brocard</monger>
</rsp>
ENDOFEXPECTED
}

{
my $frs = Froody::Response::String->new();
$frs->set_bytes( <<ENDOFRSP );
<?xml version="1.0" encoding="utf-8" ?>
<rsp stat="ok">
  <monger>L\x{c3}\x{a9}on Brocard</monger>
</rsp>
ENDOFRSP

is($frs->render, <<ENDOFEXPECTED, "got expected output back");
<?xml version="1.0" encoding="utf-8" ?>
<rsp stat="ok">
  <monger>L\x{c3}\x{a9}on Brocard</monger>
</rsp>
ENDOFEXPECTED

######
# testing method storing stuff

my $method = Froody::Method->new();
is($frs->structure, undef, "no method yet");
$frs->structure($method);
is($frs->structure, $method, "method now!");

throws_ok
{
  $frs->structure("this.just.a.name");
} "Froody::Error", "must use real method";

ok(Froody::Error::err("perl.methodcall.param"), "right error thrown")
  or diag $@;

}

######
# testing the cookie stuff
my $frs = Froody::Response::String->new();
$frs->add_cookie( name => "wibble", value => "bar", expires => "+365d",
                  domain => "opensource.fotango.com", path => "/svn" );

is(@{$frs->cookie},1, "there's a cookie");
is($frs->cookie->[0]->name,    "wibble",                 "name on cookie ok");
is($frs->cookie->[0]->value,   "bar",                    "value on cookie ok");
is($frs->cookie->[0]->domain,  "opensource.fotango.com", "domain on cookie ok");
is($frs->cookie->[0]->path,    "/svn",                   "path on cookie ok");

my $year = 1900+((gmtime)[5])+1;
like($frs->cookie->[0]->expires, qr/$year/, "expires on cookie ok");
