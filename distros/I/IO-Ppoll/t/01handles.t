#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Ppoll qw( POLLIN POLLOUT POLLHUP );

my $ppoll = IO::Ppoll->new();

ok( defined $ppoll, 'defined $ppoll' );
isa_ok( $ppoll, "IO::Ppoll", '$ppoll isa IO::Ppoll' );

is_deeply( [ $ppoll->handles ], [], 'handles when empty' );

$ppoll->mask( \*STDIN, POLLIN );

is_deeply( [ $ppoll->handles ], [ \*STDIN ], 'handles after adding STDIN' );

is( $ppoll->mask( \*STDIN ), POLLIN, 'mask(STDIN) after adding' );

$ppoll->mask( \*STDIN, POLLIN|POLLHUP );

is( $ppoll->mask( \*STDIN ), POLLIN|POLLHUP, 'mask(STDIN) after changing mask' );

$ppoll->mask_add( \*STDIN, POLLOUT );

is( $ppoll->mask( \*STDIN ), POLLIN|POLLOUT|POLLHUP, 'mask(STDIN) after mask_add' );

$ppoll->mask_del( \*STDIN, POLLHUP );

is( $ppoll->mask( \*STDIN ), POLLIN|POLLOUT, 'mask(STDIN) after mask_del' );

$ppoll->remove( \*STDIN );

is_deeply( [ $ppoll->handles ], [], 'handles after removing STDIN' );

done_testing;
