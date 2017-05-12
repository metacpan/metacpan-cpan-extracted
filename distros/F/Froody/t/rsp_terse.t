#!/usr/bin/perl

###########################################################################
# This tests the basic functionality of Froody::Response::Terse
#
# It does not feature conversion tests;  Those are in rsp_convert.t
###########################################################################

use strict;
use warnings;

# Test modules we might want to use:
# use Test::DatabaseRow;
use Test::Exception;
use Devel::Peek;

# start the tests
use Test::More tests => 9;

use_ok("Froody::Response");
use_ok("Froody::Response::Terse");
use_ok("Froody::Method");

# make a method
my $method = Froody::Method->new();
$method->full_name("fotango.staff.getGroup");
$method->structure({ 
  'people' => {
     attr => ['group'],
     elts => [qw/person/],
     text => 1,
  },
  'people/person' => {
     elts => [qw/name/],
     attr => [qw/nick number/],
     multi => 1,
   },
  'people/person/name' => { text => 1, multi => 0, elts => [], attr => [] }
});
$method->arguments({ 'group' => {
   multiple => 0, 
   optional => 0,
   doc => 'The Group Name',
   type => 'scalar', #user defined type label.
}});

my $terse = Froody::Response::Terse->new();
isa_ok($terse, "Froody::Response::Terse");
isa_ok($terse, "Froody::Response");

$terse->structure($method);
$terse->content({
   group => "frameworks",
   person => [
    { nick => "clkao",    number => "243", name => "Chia-liang Kao" },
    { nick => "Trelane",  number => "234", name => "Mark Fowler"    },
    { nick => "Nicholas", number => "238", name => "Nicholas Clark" },
    { nick => "nnunley",  number => "243", name => "Norman Nunley"  },
    { nick => "skugg",    number => "214", name => "Stig Brautaset" },
    { nick => "jerakeen", number => "235", name => "Tom Insam"      },
   ],
   -text => "Frameworks is a department of Fotango.  We work on lots of\n".
            "software, including writing tools like Froody.",
});

# let's try to render that
my $bytes = $terse->render;
ok(index(
  $bytes,
  '<person number="234" nick="Trelane"><name>Mark Fowler</name></person>'
  ) > -1,"I'm in there") or Dump($bytes);
ok(index(
  $bytes,
  '<person number="214" nick="skugg"><name>Stig Brautaset</name></person>'
  ) > -1,"Stig's in there") or Dump($bytes);
ok(index(
  $bytes,
  '<?xml version="1.0" encoding="utf-8"'
  ) > -1,"xml works") or Dump($bytes);

$terse->content({
   group => "French military people that were in Bill & Ted's Excellent Adventure",
   person => [
    { nick => "Napol\x{e9}on", number => "69", name => "Napol\x{e9}on Bonaparte" },
   ],
   -text => "I don't think it's gonna work dude",
});

$bytes = $terse->render;
ok(index(
  $bytes,
  "<person number=\"69\" nick=\"Napol\303\251on\"><name>Napol\303\251on Bonaparte</name></person>"
  ) > -1,"Boney's fine") or Dump($bytes);
