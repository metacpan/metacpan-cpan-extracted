#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Handle::Packable;

my $fh = IO::Handle::Packable->new;
$fh->open( \my $buffer, ">" );

{
   $fh->pack( "c C a5", 1, 2, "hello" );

   is( $buffer, "\x01\x02hello", '$fh->pack outputs values' );
}

done_testing;
