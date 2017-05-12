#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;
use IO::Async::Test;
use IO::Async::Loop;

use IPC::PerlSSH::Async;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my @exitparams;

my $ips = IPC::PerlSSH::Async->new(
   Command => "$^X",

   on_exit => sub { @exitparams = @_ },
);

$loop->add( $ips );

my $result;
my $exception;

$ips->eval(
   code => 'return "hello"',
   args => [],
   on_result    => sub { $result = shift },
   on_exception => sub { $exception = shift },
);

undef $result;
wait_for { defined $result or defined $exception };

is( $result, "hello",        '$result after non-exit' );
is( $exception, undef,       '$exception after non-exit' );
is_deeply( \@exitparams, [], '@exitparams after non-exit' );

$ips->eval(
   code => 'exit 2',
   args => [],
   on_result    => sub { $result = shift },
   on_exception => sub { $exception = shift },
);

undef $result;
wait_for { defined $exception and @exitparams };

is( $result, undef,                         '$result after exit' );
is( $exception, "Remote connection closed", '$exception after exit' );
is( $exitparams[1], 2<<8, '@exitparams after exit' );
