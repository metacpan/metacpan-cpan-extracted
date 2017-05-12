#!perl

use Test::More tests => 9;

use warnings;
use strict;

use JavaScript;

my $rt1 = new JavaScript::Runtime();
my $cx1 = $rt1->create_context();

ok( my $foo = $cx1->eval(q!
    foo = { 'bar':1 }
    foo.baz = foo; // scary recursiveness
    foo
  !) );
is( $foo->{baz}, $foo, "recursive structure returned." );

# test that we can pass the structure _back_ into JS space.
ok( my $uneval = $cx1->call('uneval', $foo ), "unevaled"); die $@ if $@;
ok( my $foo2 = $cx1->eval("eval('$uneval')"), "evalled" ); die $@ if $@;

is( $foo2->{baz}, $foo2, "recursive structure returned." );


ok( my $bar = $cx1->eval(q!
    foo = [ 'bar' ]
    foo[1] = foo; // scary recursiveness
    foo
  !) );
is( $bar->[1], $bar, "recursive structure returned." );

# test that we can pass the structure _back_ into JS space.
ok( $uneval = $cx1->call('uneval', $bar ), "unevaled"); die $@ if $@;
ok( my $bar2 = $cx1->eval("eval('$uneval')"), "evalled" ); die $@ if $@;
