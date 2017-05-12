#!/usr/bin/perl

use strict;
use warnings;

use Error qw(:try);
use Test::More tests => 8;

my $dollar_at;
my $arg_0;

try {
    throw Error::Simple( "message" );
}
catch Error::Simple with {
    $arg_0 = shift;
    $dollar_at = $@;
};

ok( defined $arg_0,     'defined( $_[0] ) after throw/catch' );
ok( defined $dollar_at, 'defined( $@ ) after throw/catch' );
ok( ref $arg_0     && $arg_0->isa( "Error::Simple" ),     '$_[0]->isa( "Error::Simple" ) after throw/catch' );
ok( ref $dollar_at && $dollar_at->isa( "Error::Simple" ), '$@->isa( "Error::Simple" ) after throw/catch' );

try {
    throw Error::Simple( "message" );
}
otherwise {
    $arg_0 = shift;
    $dollar_at = $@;
};

ok( defined $arg_0,     'defined( $_[0] ) after throw/otherwise' );
ok( defined $dollar_at, 'defined( $@ ) after throw/otherwise' );
ok( ref $arg_0     && $arg_0->isa( "Error::Simple" ),     '$_[0]->isa( "Error::Simple" ) after throw/otherwise' );
ok( ref $dollar_at && $dollar_at->isa( "Error::Simple" ), '$@->isa( "Error::Simple" ) after throw/otherwise' );
