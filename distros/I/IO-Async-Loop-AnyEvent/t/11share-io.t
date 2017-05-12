#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use AnyEvent;
use IO::Async::Loop::AnyEvent;
use IO::Async::Stream;

sub make_readable_handle
{
   pipe( my $reader, my $writer ) or die "Cannot pipe() - $!";

   syswrite $writer, "Hello world!\n" or die "Cannot syswrite - $!";

   return $reader;
}

my $loop = IO::Async::Loop::AnyEvent->new;

my $anyevent_line;

my $anyevent_buffer = "";
my $anyevent_handle = make_readable_handle;
my $w = AnyEvent->io(
   fh   => $anyevent_handle,
   poll => "r",
   cb   => sub {
      sysread $anyevent_handle, $anyevent_buffer, 8192, length $anyevent_buffer;
      $anyevent_line = $1 if $anyevent_buffer =~ s/^(.*)\n//;
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

$loop->loop_once until defined $anyevent_line and defined $ioasync_line;

is( $anyevent_line, "Hello world!", 'AnyEvent read' );
is( $ioasync_line,  "Hello world!", 'IO::Async read' );
