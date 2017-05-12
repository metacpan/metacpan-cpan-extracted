use strict;
use warnings;
use Test::More;

use FFI::Me;

my $floor;
my $niner;
eval {
    $floor = FFI::Raw->new( undef, "floor", FFI::Raw::double, FFI::Raw::double );
    $niner = $floor->call(9.8);
};

plan skip_all => 'Could not find test FFI, skipping.' if $@ || $niner ne '9';

diag("Testing FFI::Me $FFI::Me::VERSION");

package Test::Foo;

use FFI::Me;

sub new { return bless {}, shift }

ffi floor => (
    rv  => ffi::double,
    arg => [ffi::double],
);

ffi floor_meth => (
    rv     => ffi::double,
    arg    => [ffi::double],
    sym    => 'floor',
    method => 1,
);

package main;

ok( defined &Test::Foo::floor, 'function exists' );
is( Test::Foo::floor(9.8), 9, 'function works (rv option and arg option)' );
ok( defined &Test::Foo::floor_meth, 'method exists' );
my $obj = Test::Foo->new;
is( $obj->floor_meth(9.8), 9, 'method works (method option and sym option)' );

my $lib;
$lib = '/usr/lib/libm.so' if -f '/usr/lib/libm.so';
if ( !$lib ) {
    $lib = '/usr/lib/libm.dylib' if -f '/usr/lib/libm.dylib';
}

if ($lib) {
    ffi cos => (
        lib => $lib,
        rv  => ffi::double,
        arg => [ffi::double],
    );

    ok( defined &cos, 'lib results exists' );
    cmp_ok( cos(1.2), '>', 0, "lib results works" );
}
else {
    diag "Skipping lib tests (/usr/lib/libm.[so|dylib] does not exist)";
}

eval { ffi herp => (); };
ok( $@, 'fatal when the args can not be done' );

done_testing;
