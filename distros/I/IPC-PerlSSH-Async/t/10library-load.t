#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;
use Test::Refcount;
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

my $loaded;

is_refcount( $ips, 2, '$ips has 2 refcount before use_library' );

$ips->use_library(
   library => "t::Math",
   funcs   => [qw( sum )],
   on_loaded => sub { $loaded = 1 },
);

wait_for { $loaded };

is_refcount( $ips, 2, '$ips has 2 refcount after library loaded' );

my $total;
$ips->call(
   name => 'sum',
   args => [ 10, 20, 30 ],
   on_result => sub { $total = shift },
);

wait_for { defined $total };

is( $total, 60, '$total is 60' );

$loaded = 0;
$ips->use_library(
   library => "t::Math",
   on_loaded => sub { $loaded = 1 },
);

wait_for { $loaded };

is( $loaded, 1, 'Loading t::Math a second time succeeds' );

my $exception;
$ips->use_library(
   library => "t::Math",
   funcs => [qw( missingfunc )],
   on_loaded => sub { die "Loading a missing function does not fail" },
   on_exception => sub { $exception = shift },
);

wait_for { $exception };

like( $exception,
      qr/^t::Math does not define a library function called missingfunc /,
      'Loading a missing function fails' );

undef $exception;
$ips->use_library(
   library => "a::library::that::does::not::exist",
   on_loaded => sub { die "Loading a missing library does not fail" },
   on_exception => sub { $exception = shift },
);

wait_for { $exception };

like( $exception,
      qr/^Cannot find an IPC::PerlSSH library called a::library::that::does::not::exist /,
      'Loading a missing library fails' );

$loop->remove( $ips );

is_oneref( $ips, '$ips has 1 refcount at EOF' );
