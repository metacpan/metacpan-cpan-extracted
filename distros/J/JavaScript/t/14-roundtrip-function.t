#!perl

use strict;
use warnings;

use JavaScript;
use Test::More tests => 5;

my $rt = JavaScript::Runtime->new;
my $cx = $rt->create_context;
$cx->bind_function( name => 'ok', func => sub { main::ok($_[0], $_[1]); } );
my $foo = $cx->eval(q!var f = function() { return 1 }; f;!);
isa_ok($foo, 'JavaScript::Function');
is($cx->call($foo), 1);
is($foo->(), 1);
my $bar = $cx->eval(q!var b = function() { ok(arguments[0](),"should have roundtripped"); }; b;!);
$cx->call($bar, $foo);
$bar->($foo);
