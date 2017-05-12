#!/usr/bin/perl

use strict;
use warnings;
use EO::Array;
use Test::More no_plan => 1;

use_ok( 'EO::Class' );
my $thing = EO::Array->new();
my $class = EO::Class->new_with_object( $thing );
my $methods = $class->methods;

isa_ok( $methods, 'EO' );
isa_ok( $methods, 'EO::Array' );

ok( $methods->count > 1 );
ok( my $method = $methods->at( 0 ) );

isa_ok( $method, 'EO' );
isa_ok( $method, 'EO::Method' );
can_ok( $method, 'name' );
can_ok( $method, 'reference');
can_ok( $method, 'call' );


ok( my $path = $class->path() );
isa_ok( $path, 'EO' );
ok( $path->isa('EO::File') || $path->isa('EO::File::Stub') );

my $that;
eval {
  $that = EO::Class->new();
};
ok(!$@);

eval {
  $that->methods;
};
ok($@);
isa_ok($@,'EO::Error');
isa_ok($@,'EO::Error::InvalidState');

$that->name('EO::Class');
my $classes = $that->parents();
isa_ok( $classes, 'EO' );
isa_ok( $classes, 'EO::Array');

isa_ok( $class = $classes->at( 0 ), 'EO::Class' );
is($class->name, 'EO');
ok(!$class->can_delegate());
ok($class->loaded, q{it had better be, we're testing it now...});

ok($class = EO::Class->new_with_classname( 'EO::Hash' ));
ok($class->load());
ok($class->loaded(),"Path is " . $class->path->as_string);

ok(my $meth = EO::Method->new(),"testing add_method");
ok($meth->reference( sub { $::WHOOT="YES" } ));
ok($meth->name('funfun'));
ok($class->add_method( $meth ));
ok(EO::Hash->funfun);
is($::WHOOT,'YES');

my @methods = $class->methods;
ok(scalar(@methods) > 1, "arrayification worked: " . scalar(@methods) . " elements in list");


1;
