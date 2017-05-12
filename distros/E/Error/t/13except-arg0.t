#!/usr/bin/perl

use strict;
use warnings;

use Error qw(:try);
use Test::More tests => 2;

my $arg_0;

try {
    throw Error::Simple( "message" );
}
except {
    $arg_0 = shift;
    return {
      'Error::Simple' => sub {},
    };
};

ok( defined $arg_0,     'defined( $_[0] ) after throw/except' );
ok( ref $arg_0     && $arg_0->isa( "Error::Simple" ),     '$_[0]->isa( "Error::Simple" ) after throw/except' );
