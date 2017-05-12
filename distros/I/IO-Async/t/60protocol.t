#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Identity;
use Test::Refcount;

use IO::Async::Loop;

use IO::Async::OS;

use IO::Async::Handle;
use IO::Async::Protocol;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot create socket pair - $!";

# Need sockets in nonblocking mode
$S1->blocking( 0 );
$S2->blocking( 0 );

my $handle = IO::Async::Handle->new(
   handle => $S1,
   on_read_ready  => sub {},
   on_write_ready => sub {},
);

my @setup_args;
my @teardown_args;
my $readready;
my $writeready;

my $proto = TestProtocol->new;

ok( defined $proto, '$proto defined' );
isa_ok( $proto, "IO::Async::Protocol", '$proto isa IO::Async::Protocol' );

is_oneref( $proto, '$proto has refcount 1 initially' );

$proto->configure( transport => $handle );

identical( $proto->transport, $handle, '$proto->transport' );

is( scalar @setup_args, 1, '@setup_args after configure transport' );
identical( $setup_args[0], $handle, '$setup_args[0] after configure transport');

undef @setup_args;

is_oneref( $proto, '$proto has refcount 1 after configure transport' );
# lexical $handle, $proto->{transport}, $proto->{children} == 3
is_refcount( $handle, 3, '$handle has refcount 3 after proto configure transport' );

$loop->add( $proto );

is_refcount( $proto, 2, '$proto has refcount 2 after adding to Loop' );
is_refcount( $handle, 4, '$handle has refcount 4 after adding proto to Loop' );

$S2->syswrite( "hello\n" );

wait_for { $readready };

is( $readready, 1, '$readready after wait' );

# Just to shut poll/select/etc... up
$S1->sysread( my $dummy, 8192 );

my $newhandle = IO::Async::Handle->new(
   handle => $S1,
   on_read_ready  => sub {},
   on_write_ready => sub {},
);

$proto->configure( transport => $newhandle );

identical( $proto->transport, $newhandle, '$proto->transport after reconfigure' );

is( scalar @teardown_args, 1, '@teardown_args after reconfigure transport' );
identical( $teardown_args[0], $handle, '$teardown_args[0] after reconfigure transport');

is( scalar @setup_args, 1, '@setup_args after reconfigure transport' );
identical( $setup_args[0], $newhandle, '$setup_args[0] after reconfigure transport');

undef @teardown_args;
undef @setup_args;

is_oneref( $handle, '$handle has refcount 1 after reconfigure' );

my $closed = 0;
$proto->configure(
   on_closed => sub { $closed++ },
);

$proto->transport->close;

wait_for { $closed };

is( $closed, 1, '$closed after stream close' );

is( $proto->transport, undef, '$proto->transport is undef after close' );

is_refcount( $proto, 2, '$proto has refcount 2 before removal from Loop' );

$loop->remove( $proto );

is_oneref( $proto, '$proto has refcount 1 before EOF' );

done_testing;

package TestProtocol;
use base qw( IO::Async::Protocol );

sub setup_transport
{
   my $self = shift;
   @setup_args = @_;

   my ( $transport ) = @_;

   $self->SUPER::setup_transport( $transport );

   $transport->configure(
      on_read_ready  => sub { $readready = 1 },
      on_write_ready => sub { $writeready = 1 },
   );
}

sub teardown_transport
{
   my $self = shift;
   @teardown_args = @_;

   my ( $transport ) = @_;
   $transport->configure(
      on_read_ready  => sub {},
      on_write_ready => sub {},
   );

   $self->SUPER::teardown_transport( $transport );
}
