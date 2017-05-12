#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Math::Random::OO  

use Test::More tests => 6;

my @fcns;
BEGIN { @fcns = qw (Uniform UniformInt Normal Bootstrap) }
BEGIN { use_ok( 'Math::Random::OO', @fcns ); }
can_ok( 'main', @fcns );

my $obj;
for (@fcns) {
    no strict 'refs';
    $obj = &{$_}(0,1);
    isa_ok( $obj, "Math::Random::OO::$_" );
}
