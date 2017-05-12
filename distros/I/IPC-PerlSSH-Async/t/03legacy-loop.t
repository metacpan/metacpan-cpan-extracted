#!/usr/bin/perl -w

use strict;

use Test::More tests => 3;
use Test::Warn;

use IO::Async::Test;
use IO::Async::Loop;

use IPC::PerlSSH::Async;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $ips;
warning_is {
   $ips = IPC::PerlSSH::Async->new(
      Command => "$^X",
      loop => $loop,

      on_exception => sub { die "Perl died early - $_[0]" },
   );
} "'loop' constructor argument is deprecated", 'loop constructor argument gives deprecation warning';

ok( defined $ips, "Constructor" );

my $result;
$ips->eval( 
   code => '1 + 1',
   on_result => sub { $result = shift },
);

wait_for { defined $result };

is( $result, 2, "Legacy 'loop' argument still works" );
