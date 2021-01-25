#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use UV;
use UV::Poll;
use IO::Async::Loop::UV;
use IO::Async::Stream;

sub make_readable_handle
{
   pipe( my $reader, my $writer ) or die "Cannot pipe() - $!";

   syswrite $writer, "Hello world!\n" or die "Cannot syswrite - $!";

   return $reader;
}

my $loop = IO::Async::Loop::UV->new;

my $uv_line;

my $uv_buffer = "";
my $uv_handle = make_readable_handle;
my $uv_poll = UV::Poll->new(fd => $uv_handle->fileno);
$uv_poll->start(UV::Poll::UV_READABLE, sub {
   sysread $uv_handle, $uv_buffer, 8192, length $uv_buffer;
   $uv_line = $1 if $uv_buffer =~ s/^(.*)\n//;
});

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

$loop->loop_once until defined $uv_line and defined $ioasync_line;

is( $uv_line,      "Hello world!", 'UV read' );
is( $ioasync_line, "Hello world!", 'IO::Async read' );

done_testing;
