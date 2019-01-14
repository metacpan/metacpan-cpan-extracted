#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Config;
use Devel::MAT::Dumper;

my $DUMPFILE = "test.pmat";

Devel::MAT::Dumper::dump( $DUMPFILE );
END { unlink $DUMPFILE; }

pass "Write dumpfile";

open my $fh, "<", $DUMPFILE or
   die "Cannot open $DUMPFILE for reading - $!";

read $fh, my $buf, 12;
my ( $sig, $flags, $zero, $major, $minor, $perlver ) =
   unpack "A4 C C C C I", $buf;

is( $sig, "PMAT", 'File magic signature' );

is( $flags,
    ( $Config{byteorder} =~ m/4321$/ ? 0x01 : 0x00 ) |
    ( $Config{uvsize} == 8           ? 0x02 : 0x00 ) |
    ( $Config{ptrsize} == 8          ? 0x04 : 0x00 ) |
    ( $Config{nvsize} > 8            ? 0x08 : 0x00 ) |
    ( $Config{useithreads}           ? 0x10 : 0x00 ),
    'Flags' );

is( $zero, 0, 'Zero' );

is( $major, 0, 'Major' );

is( $minor, 4, 'Minor' );

my ( $rev, $sub ) = $] =~ m/^5\.(...)(...)$/;
is( $perlver, ( 5 << 24 ) | ( $rev << 16 ) | ( $sub + 0 ), 'Perlver' );

done_testing;
