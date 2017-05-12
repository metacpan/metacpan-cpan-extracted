#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Fatal;
use Test::Refcount;

use POSIX qw( SIGTERM );

use IO::Async::Signal;

use IO::Async::Loop;
use IO::Async::OS;

plan skip_all => "This OS does not have signals" unless IO::Async::OS->HAVE_SIGNALS;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

my $caught = 0;

my @rargs;

my $signal = IO::Async::Signal->new(
   name => 'TERM',
   on_receipt => sub { @rargs = @_; $caught++ },
);

ok( defined $signal, '$signal defined' );
isa_ok( $signal, "IO::Async::Signal", '$signal isa IO::Async::Signal' );

is_oneref( $signal, '$signal has refcount 1 initially' );

is( $signal->notifier_name, "TERM", '$signal->notifier_name' );

$loop->add( $signal );

is_refcount( $signal, 2, '$signal has refcount 2 after adding to Loop' );

$loop->loop_once( 0.1 ); # nothing happens

is( $caught, 0, '$caught idling' );

kill SIGTERM, $$;

wait_for { $caught };

is( $caught, 1, '$caught after raise' );
is_deeply( \@rargs, [ $signal ], 'on_receipt args after raise' );

my $caught2 = 0;

my $signal2 = IO::Async::Signal->new(
   name => 'TERM',
   on_receipt => sub { $caught2++ },
);

$loop->add( $signal2 );

undef $caught;

kill SIGTERM, $$;

wait_for { $caught };

is( $caught,  1, '$caught after raise' );
is( $caught2, 1, '$caught2 after raise' );

$loop->remove( $signal2 );

undef $caught; undef $caught2;

kill SIGTERM, $$;

wait_for { $caught };

is( $caught,  1,     '$caught after raise' );
is( $caught2, undef, '$caught2 after raise' );

undef $caught;
my $new_caught;
$signal->configure( on_receipt => sub { $new_caught++ } );

kill SIGTERM, $$;

wait_for { $new_caught };

is( $caught, undef, '$caught after raise after replace on_receipt' );
is( $new_caught, 1, '$new_caught after raise after replace on_receipt' );

undef @rargs;

is_refcount( $signal, 2, '$signal has refcount 2 before removing from Loop' );

$loop->remove( $signal );

is_oneref( $signal, '$signal has refcount 1 finally' );

undef $signal;

## Subclass

my $sub_caught = 0;

$signal = TestSignal->new(
   name => 'TERM',
);

ok( defined $signal, 'subclass $signal defined' );
isa_ok( $signal, "IO::Async::Signal", 'subclass $signal isa IO::Async::Signal' );

is_oneref( $signal, 'subclass $signal has refcount 1 initially' );

$loop->add( $signal );

is_refcount( $signal, 2, 'subclass $signal has refcount 2 after adding to Loop' );

$loop->loop_once( 0.1 ); # nothing happens

is( $sub_caught, 0, '$sub_caught idling' );

kill SIGTERM, $$;

wait_for { $sub_caught };

is( $sub_caught, 1, '$sub_caught after raise' );

ok( exception {
      my $signal = IO::Async::Signal->new(
         name => 'this signal name does not exist',
         on_receipt => sub {},
      );
      $loop->add( $signal );
   },
   'Bad signal name fails'
);

done_testing;

package TestSignal;
use base qw( IO::Async::Signal );

sub on_receipt { $sub_caught++ }
