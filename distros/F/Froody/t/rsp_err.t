#!/usr/bin/perl

###########################################################################
# This tests the basic functionality of Froody::Response::Error
#
# It does not feature conversion tests;  Those are in rsp_convert.t
###########################################################################

use strict;
use warnings;

# colourising the output if we want to
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

###################################
# user editable parts

use Test::Exception;
use Test::XML;

# start the tests
use Test::More tests => 21;

use_ok("Froody::Response::Error");
use_ok("Froody::ErrorType");

try("You suck", <<'XML');
<?xml version="1.0" encoding="utf-8"?>
<rsp stat="fail">
  <err code="unknown" msg="You suck"/>
</rsp>
XML

# this relies on the fact that an Error object stringifys to "Died".  If this
# ever changes this test will fail
try(Error->new(), <<'XML');
<?xml version="1.0" encoding="utf-8"?>
<rsp stat="fail">
  <err code="unknown" msg="Died"/>
</rsp>
XML

try(Froody::Error->new("beer.notenough", "Running out of Beer!"), <<'XML');
<?xml version="1.0" encoding="utf-8"?>
<rsp stat="fail">
  <err code="beer.notenough" msg="Running out of Beer!"/>
</rsp>
XML

throws_ok
{
  Froody::Response::Error->new->set_error(
    Froody::Error->new("wham.overheating", "The WHAM! is overheating")
  )->throw;
} "Froody::Error";

ok(Froody::Error::err("wham"), "wham!");
ok(Froody::Error::err("wham.overheating"), "wham overheating!");
is($@->message, "The WHAM! is overheating");

throws_ok
{
  Froody::Response::Error->new->set_error(
    "fish!"
  )->throw;
} "Froody::Error";

ok(Froody::Error::err("unknown"), "unknown");
is($@->message, "fish!");

throws_ok
{
  Froody::Response::Error->new->set_error(
    Error->new
  )->throw;
} "Froody::Error";

ok(Froody::Error::err("unknown"), "unknown");
is($@->message, "Died");  # again, relies on known stringification of Error

#####################################
use Test::Builder;

sub try
{
  my ($error, $string) = @_;
  my ($r, $xml);

  my $Test = Test::Builder->new;  #Note: this is a singleton.
  local $Test::Builder::Level = 1;
                     
  $Test->ok( $r = Froody::Response::Error->new
                                  ->set_error($error)
                                  ->structure(Froody::ErrorType->new()),
  "it's an error");
  $Test->ok( $xml = $r->render, "got XML" );
  is_xml( $xml, $string, "correct XML")
    or diag("GOT:\n".RED($xml)."\nEXPECTED:\n".CYAN($string));
}
