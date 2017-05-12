#!/usr/bin/perl

###########################################################################
# This tests the basic functionality of Froody::Response::XML
###########################################################################

use strict;
use warnings;

# start the tests
use Test::More tests => 4;

use_ok("Froody::Response::XML");
my $xml = Froody::Response::XML->new();
isa_ok($xml, "Froody::Response::XML");

use XML::LibXML;
my $xml_doc = XML::LibXML::Document->new( "1.0", "utf-8" );
  
# create the rsp
my $rsp = $xml_doc->createElement("rsp");
$rsp->setAttribute("stat", "ok");
$xml_doc->setDocumentElement($rsp);
  
# add the child node foo
my $foo = $xml_doc->createElement("foo");
$foo->appendText("L\x{c3}\x{a9}on");
$rsp->appendChild($foo);

$xml->xml($xml_doc);
my $bytes = $xml->render;
like($bytes, qr[<foo>L\x{c3}\x{a9}on</foo>], "contains right thing");
like($bytes, qr[^<\?xml version="1\.0" encoding="utf-8"\s*\?>], "contains right header");

