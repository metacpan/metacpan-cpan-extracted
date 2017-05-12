#!perl

use Test::More tests => 3;

use strict;
use warnings;

use JavaScript;

my $rt1 = JavaScript::Runtime->new;
my $cx1 = $rt1->create_context;

$cx1->eval( do { local $/; <DATA> } );

$cx1->bind_function( name => 'ok', func => sub { main::ok($_[0], $_[1]); } );
$cx1->bind_function( name => 'say', func => sub {print @_,"\n" } );

my $code  = "var b = new Balloon(); Balloon.prototype.test";
my $fn = $cx1->eval( $code );

my $obj = { message => 'okay called from inside context' };
my $result = JavaScript::Context::jsc_call_in_context(
                                                      $cx1,
                                                      $fn,
                                                      [],
                                                      {%{$obj}},
                                                      'b'
                                                  );

ok($result, "we received a true result");
is($obj->{message}, $result, "call in context worked fine");

__DATA__

var Balloon = function() {};

Balloon.prototype.ok_in_context = function( testmessage ) {
  ok( true, testmessage );
};

Balloon.prototype.test = function() {
  this.ok_in_context( this.message );
  return this.message;
}
