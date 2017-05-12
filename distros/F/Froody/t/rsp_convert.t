#!/usr/bin/perl

###########################################################################
# This tests coverting from one Froody::Response object into another. It
# contains tests for many of the Froody::Response::* subclasses
###########################################################################

use strict;
use warnings;

use Test::Exception;
use Data::Dumper;

# start the tests
use Test::More tests => 38;

use_ok("Froody::Response");
use_ok("Froody::Method");
use_ok("Froody::ErrorType");

# make a method.  This would normally come from XML, but hey, ho, this is
# a test innit.
my $method = Froody::Method->new();
$method->full_name("perl.pm.groups");
my $texty ={ text => 1, multi => 0, attr => [], elts => [] };
$method->structure({ 
  'mongers' => {
     attr => ['group'],
     elts => [qw/monger/],
     text => 1,
  },
  'mongers/monger' => {
     attr => [qw/nick/],
     text => 1,
     multi => 1,
   },
  'mongers/monger/nick' => $texty
});

my $method2 = Froody::Method->new();
$method2->full_name("perl.pm.groupsDetailed");
$method2->structure({ 
  'mongers' => {
     attr => ['group'],
     elts => [qw/monger/],
     text => 1,
  },
  'mongers/monger' => {
     attr => [qw/nick/],
     elts => [qw/name email/],
     text => 1,
     multi => 1,
   },
   'mongers/monger/name' => $texty,
   'mongers/monger/email' => $texty,
});

#####
# convert a string to an XML

{
use Froody::Response::String;
my $frs = Froody::Response::String->new()->structure($method);
isa_ok($frs,"Froody::Response", "got a froody response back");
$frs->set_string( <<ENDOFRSP );
<rsp stat="ok">
  <mongers group="london.pm">
   <monger nick="acme">L\x{e9}on Brocard</monger>
   <monger nick="Trelane">Mark Fowler</monger>
  </mongers>
</rsp>
ENDOFRSP

use Froody::Response::XML;
my $xml = $frs->as_xml;
isa_ok($xml, "Froody::Response::XML");
is($xml->xml->findvalue('/rsp/@stat'), "ok", "rsp has ok");
is($xml->xml->findvalue('/rsp/mongers/@group'), "london.pm", "london.pm");
is($xml->xml->findvalue('/rsp/mongers/monger[1]/@nick'), "acme", "nick is acme");
is($xml->xml->findvalue('/rsp/mongers/monger[1]/text()'), "L\x{e9}on Brocard", "name is leon");
is($xml->xml->findvalue('/rsp/mongers/monger[2]/@nick'), "Trelane", "nick is Trelane");
is($xml->xml->findvalue('/rsp/mongers/monger[2]/text()'), "Mark Fowler", "name is mark");
is($xml->structure, $method, "method matches");
}

####
# convert a string to a PerlDS

{
use Froody::Response::String;
my $frs = Froody::Response::String->new()->structure($method);
isa_ok($frs,"Froody::Response", "got a froody response back");
$frs->set_string( <<ENDOFRSP );
<rsp stat="ok">
  <mongers group="london.pm">
   <monger nick="acme">L\x{e9}on Brocard</monger>
   <monger nick="Trelane">Mark Fowler</monger>
  </mongers>
</rsp>
ENDOFRSP

use Froody::Response::PerlDS;
my $perlds = $frs->as_perlds;
isa_ok($perlds, "Froody::Response::PerlDS");
is_deeply($perlds->content, {
  name => "mongers",
  attributes => { "group" => "london.pm" },
  children => [
    {
       name => "monger",
       attributes => { nick => "acme" },
       value => "L\x{e9}on Brocard"
    },
    {
       name => "monger",
       attributes => { nick => "Trelane" },
       value => "Mark Fowler"
    },
  ],
 },"right content");
is($perlds->structure, $method, "method matches");

# okay, now converting from a perlDS directly to an XML doesn't 
# go via a string.  Let's check that worked fine

my $xml = $perlds->as_xml;
isa_ok($xml, "Froody::Response::XML");
is($xml->xml->findvalue('/rsp/@stat'), "ok", "rsp has ok");
is($xml->xml->findvalue('/rsp/mongers/@group'), "london.pm", "london.pm");
is($xml->xml->findvalue('/rsp/mongers/monger[1]/@nick'), "acme", "nick is acme");
is($xml->xml->findvalue('/rsp/mongers/monger[1]/text()'), "L\x{e9}on Brocard", "name is leon");
is($xml->xml->findvalue('/rsp/mongers/monger[2]/@nick'), "Trelane", "nick is Trelane");
is($xml->xml->findvalue('/rsp/mongers/monger[2]/text()'), "Mark Fowler", "name is mark");
is($xml->structure, $method, "method matches");
}


#####
# convert a string to a Terse

{
use_ok("Froody::Response::Terse");
my $frs = Froody::Response::String->new()->structure($method2);
isa_ok($frs,"Froody::Response", "got a froody response back");
$frs->set_string( <<"ENDOFRSP" );
<rsp stat="ok">
  <mongers group="london.pm">
   <monger nick="acme"><name>L\x{e9}on Brocard</name><email>acme\@astray.com</email>He's an orange loving freak!</monger>
   <monger nick="Trelane"><name>Mark Fowler</name><email>mark\@twoshortplanks.com</email>
     So called Leader of London.pm
   </monger>
   It's a few m\x{f8}\x{f8}se loving members from London.pm!
  </mongers>
</rsp>
ENDOFRSP


use Data::Dumper;

my $terse = $frs->as_terse;

isa_ok($terse, "Froody::Response::Terse");
is_deeply($terse->content, {
   group => "london.pm",
   monger => [
    { nick => "acme",    name => "L\x{e9}on Brocard",
      email => 'acme@astray.com', -text =>
       "He's an orange loving freak!" },
    { nick => "Trelane", name => "Mark Fowler",
      email => 'mark@twoshortplanks.com', -text =>
       "So called Leader of London.pm" },
   ],
   -text => "It's a few m\x{f8}\x{f8}se loving members from London.pm!",

},"right content") or diag(Dumper $terse->content);

}

#####
# convert a PerlDS to an error
{

my $method = Froody::ErrorType->new();

use Froody::Response::PerlDS;
my $perlds = Froody::Response::PerlDS->new();
$perlds->status("fail");
$perlds->content({
  name => "err",
  attributes => { "msg" => "foo", code => 123 },
});
$perlds->structure($method);

# convert to the error

my $error = $perlds->as_error;
is($error->message, "foo", "err msg");
is($error->code,    123,   "err code");
is($error->structure, $method, "ds converts");

}

#####
# convert an error to XML

{

my $method = Froody::ErrorType->new();

use Froody::Response::PerlDS;
my $perlds = Froody::Response::PerlDS->new();
$perlds->status("fail");
$perlds->content({
  name => "err",
  attributes => { "msg" => "foo", code => 123 },
});
$perlds->structure($method);

# convert to the error

my $xml = $perlds->as_error->as_xml;
is($xml->xml->findvalue('/rsp/err/@msg'), "foo", "err msg");
is($xml->xml->findvalue('/rsp/err/@code'),   123, "err code");
is($xml->structure, $method,"method preserved");

}

#####
# convert an error to Terse

{

my $method = Froody::ErrorType->new();

use Froody::Response::PerlDS;
my $perlds = Froody::Response::PerlDS->new();
$perlds->status("fail");
$perlds->content({
  name => "err",
  attributes => { "msg" => "foo", code => 123 },
});
$perlds->structure($method);

# convert to the error

my $terse = $perlds->as_error->as_terse;
is($terse->status, "fail", "status");
is_deeply($terse->content,{
  msg => "foo", code => 123,
});
is($terse->structure, $method,"method preserved");

}

use Froody::Response::String;
my $gunnar = Froody::Response::String->new
                                     ->set_string(<<GUNNAR);
<rsp stat="fail">
  <err msg="Failed to login" code="zimki.error.login.invalid"/>
</rsp>
GUNNAR
is $gunnar->as_xml->status, 'fail', "We should be failing";
