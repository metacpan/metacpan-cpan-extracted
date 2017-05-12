#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'tests' => 50;

my $method;

use_ok( 'Hash::AsObject' );

# --- Make sure invocations as class methods with no args fail
foreach $method (qw/AUTOLOAD DESTROY can isa/) {
    eval { Hash::AsObject->$method }; isnt( $@, '', "invoke '$method' as a class method w/o args" );
}

# --- But can() and isa() as class methods with an arg should succeed
my $retval;

eval { $retval = Hash::AsObject->can('can') }; is( $@, '', "try to can('can')" );
ok( $retval, 'it can' );

eval { $retval = Hash::AsObject->isa('UNIVERSAL') }; is( $@, '', "try to isa('UNIVERSAL')" );
ok( $retval, "it isa" );

# --- VERSION(), import(), and new shouldn't fail
foreach $method (qw/VERSION import new/) {
    eval { Hash::AsObject->$method }; is( $@, '', "invoke '$method' as a class method" );
}

my $h = Hash::AsObject->new;
isa_ok( $h, 'Hash::AsObject' );

# --- Make sure methods that are usually special aren't actually treated specially in Hash::AsObject
foreach $method (qw/AUTOLOAD DESTROY VERSION import new/) {
    is( $h->$method(456),   456,   "set element '$method'"              );
    is( $h->$method,        456,   "get element '$method'"              );
    delete $h->{$method};
    is( $h->$method,        undef, "get non-existent element '$method'" );
    ok( !exists $h->{$method},     "don't autovivify method '$method'"  );
    is( $h->$method(undef), undef, "set undefined element '$method'"    );
    is( $h->$method,        undef, "get undefined element '$method'"    );
    ok( $h->can($method),          "make sure $method() is defined"     );
}

# --- Miscellanea
is( Hash::AsObject::VERSION(), $Hash::AsObject::VERSION, 'class method VERSION() return val' );
ok( UNIVERSAL::isa($h, 'Hash::AsObject'), 'UNIVERSAL::isa called as a function' );

