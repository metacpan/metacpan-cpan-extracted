#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

use IPC::PerlSSH;

my $ips = IPC::PerlSSH->new( Command => "$^X" );

# IPC::PerlSSH defaults to read()ing 8192 bytes at a time, so by sending
# over nine thousand we can be sure to test this boundary

my $result = $ips->eval( 'return length $_[0]', "A" x 9001 );
is( $result, 9001, 'eval with one big argument' );

$result = $ips->eval( 'return "A" x $_[0]', 9002 );
is( $result, "A" x 9002, 'eval with one big result' );

$result = $ips->eval( 'return scalar @_', map { 1 } 1 .. 9003 );
is( $result, 9003, 'eval with many little arguments' );

my @res = $ips->eval( 'return (1) x $_[0]', 9004 );
is( scalar @res, 9004, 'eval with many little results' );
