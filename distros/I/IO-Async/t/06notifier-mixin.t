#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

is_refcount( $loop, 2, '$loop has refcount 2 initially' );

my $notifier = SomeEventSource::Async->new;
my $in_loop;

isa_ok( $notifier, "SomeEventSource",     '$notifier isa SomeEventSource' );
isa_ok( $notifier, "IO::Async::Notifier", '$notifier isa IO::Async::Notifier' );

$loop->add( $notifier );

is_refcount( $loop, 2, '$loop has refcount 2 adding Notifier' );
is_refcount( $notifier, 2, '$notifier has refcount 2 after adding to Loop' );

is( $notifier->loop, $loop, 'loop $loop' );

ok( $in_loop, 'SomeEventSource::Async added to Loop' );

$loop->remove( $notifier );

is( $notifier->loop, undef, '$notifier->loop is undef' );

ok( !$in_loop, 'SomeEventSource::Async removed from Loop' );

done_testing;

package SomeEventSource;

sub new
{
   my $class = shift;
   return bless {}, $class;
}

package SomeEventSource::Async;
use base qw( SomeEventSource IO::Async::Notifier );

sub _add_to_loop      { $in_loop = 1 }
sub _remove_from_loop { $in_loop = 0 }
