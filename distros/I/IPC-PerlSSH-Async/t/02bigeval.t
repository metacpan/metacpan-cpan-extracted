#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;
use IO::Async::Test;
use IO::Async::Loop;

use IPC::PerlSSH::Async;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $ips = IPC::PerlSSH::Async->new(
   Command => "$^X",

   on_exception => sub { die "Perl died early - $_[0]" },
);

$loop->add( $ips );

# IO::Async::Stream defaults to read()ing 8192 bytes at a time, so by sending
# over nine thousand we can be sure to test this boundary

my $result;

$ips->eval(
   code => 'return length $_[0]',
   args => [ "A" x 9001 ],
   on_result => sub { $result = shift },
);

wait_for { defined $result };

is( $result, 9001, 'eval with one big argument' );

$ips->eval(
   code => 'return "A" x $_[0]',
   args => [ 9002 ],
   on_result => sub { $result = shift },
);

undef $result;
wait_for { defined $result };

is( $result, "A" x 9002, 'eval with one big result' );

$ips->eval(
   code => 'return scalar @_',
   args => [ map { 1 } 1 .. 9003 ],
   on_result => sub { $result = shift },
);

undef $result;
wait_for { defined $result };

is( $result, 9003, 'eval with many little arguments' );

my @res;
$ips->eval(
   code => 'return (1) x $_[0]',
   args => [ 9004 ],
   on_result => sub { @res = @_ },
);

wait_for { @res };

is( scalar @res, 9004, 'eval with many little results' );
