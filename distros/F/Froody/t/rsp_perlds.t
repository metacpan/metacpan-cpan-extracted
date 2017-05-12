#!/usr/bin/perl

###########################################################################
# This tests the basic functionality of Froody::Response::PerlDS
#
# It does not feature conversion tests;  Those are in rsp_convert.t
###########################################################################

use strict;
use warnings;

use Test::Exception;

# start the tests
use Test::More tests => 7;

use_ok("Froody::Response");
use_ok("Froody::Response::PerlDS");
use_ok("Froody::Method");

#####
# test the basic string stuff

{
  my $ds = { 
    name => "foo",
    children => [
      {
         name => "bar",
         value => "fish",
         children => [
            { name => "alex", attributes => { "fred" => "wilma" } },
         ],
       }
    ],
  };
 
  my $frs = Froody::Response::PerlDS->new();
  isa_ok($frs,"Froody::Response", "got a froody response back");
  $frs->content($ds);
  
  is($frs->render, <<ENDOFEXPECTED, "got expected output back");
<?xml version="1.0" encoding="utf-8"?>
<rsp stat="ok">
  <foo>
    <bar>fish<alex fred="wilma"/></bar>
  </foo>
</rsp>
ENDOFEXPECTED
  
}

#################
# encoding

{
my $ds = { 
 name => "foo",
 children => [
   {
      name => "bar",
      value => "fish",
      children => [
         { name => "alex", attributes => { "fred" => "wilma" } },
         { name => "Napol\x{e9}on", value => "\x{2744}" },
      ],
      attributes => { "l\x{e9}on" => "m\x{f8}\x{f8}se" },
   }
 ],
};

my $frs = Froody::Response::PerlDS->new();
isa_ok($frs,"Froody::Response", "got a froody response back");
$frs->content($ds);

TODO: {

local $TODO = "utf8 bug in XML::LibXML / Perl?";


is($frs->render, <<ENDOFEXPECTED, "got expected output back");
<?xml version="1.0" encoding="utf-8"?>
<rsp stat="ok">
  <foo>
    <bar l\x{c3}\x{a9}on="m\x{c3}\x{b8}\x{c3}\x{b8}se">fish<alex fred="wilma"><Napl\x{c3}\x{a9}on >\x{e2}\x{9d}\x{84}</Napl\x{c3}\x{a9}on></bar>
  </foo>
</rsp>
ENDOFEXPECTED
}

}
