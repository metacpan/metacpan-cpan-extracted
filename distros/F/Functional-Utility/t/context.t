#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;

use lib grep { -d $_ } qw(./lib ../lib);
use Functional::Utility qw(context);

my $context = scalar context;
is( $context, 'SCALAR' );

($context) = context();
is( $context, 'LIST' );

sub we_can_look_back {
	$context = context(1);
	return;
}

we_can_look_back();
is( $context, 'VOID' );

scalar we_can_look_back;
is( $context, 'SCALAR' );

my @list_context = we_can_look_back;
is( $context, 'LIST' );
