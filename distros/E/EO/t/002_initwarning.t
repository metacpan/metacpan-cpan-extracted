#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
$SIG{__WARN__} = sub { $fooTest::init_warning = 1; };

my $foo = fooTest->new();

ok( $fooTest::init );
ok( $fooTest::init_warning );

package fooTest;

use EO;
use base qw( EO );

$fooTest::init = 0;
$fooTest::init_warning = 0;

sub init {
  my $self = shift;
  $fooTest::init = 1;
}

1;
