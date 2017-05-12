#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use POE qw( Session Kernel Wheel::ReadWrite );
use IO::Async::Loop::POE;
use IO::Async::Stream;

sub make_readable_handle
{
   pipe( my $reader, my $writer ) or die "Cannot pipe() - $!";

   syswrite $writer, "Hello world!\n" or die "Cannot syswrite - $!";

   return $reader;
}

my $loop = IO::Async::Loop::POE->new;

my $poe_line;

my $wheel_readwrite;
POE::Session->create(
   inline_states => {
      _start => sub {
         $wheel_readwrite = POE::Wheel::ReadWrite->new(
            Handle => make_readable_handle,
            InputEvent => 'handle_read',
         );
      },
      handle_read => sub { $poe_line = $_[ARG0] },
   },
);

my $ioasync_line;

$loop->add(
   IO::Async::Stream->new(
      read_handle => make_readable_handle,
      on_read => sub {
         my ( $self, $buffref, $closed ) = @_;
         return if $closed;
         return 0 unless $$buffref =~ s/^(.*)\n//;

         $ioasync_line = $1;
         return 1;
      },
   )
);

$loop->loop_once until defined $poe_line and defined $ioasync_line;

is( $poe_line,     "Hello world!", 'POE read' );
is( $ioasync_line, "Hello world!", 'IO::Async read' );
