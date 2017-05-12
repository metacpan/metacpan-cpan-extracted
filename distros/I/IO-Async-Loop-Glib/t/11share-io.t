#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Glib;
use IO::Async::Loop::Glib;
use IO::Async::Stream;

sub make_readable_handle
{
   pipe( my $reader, my $writer ) or die "Cannot pipe() - $!";

   syswrite $writer, "Hello world!\n" or die "Cannot syswrite - $!";

   return $reader;
}

my $loop = IO::Async::Loop::Glib->new;

my $glib_line;

my $glib_buffer = "";
my $glib_handle = make_readable_handle;
Glib::IO->add_watch(
   $glib_handle->fileno,
   in => sub {
      sysread $glib_handle, $glib_buffer, 8192, length $glib_buffer;
      $glib_line = $1 if $glib_buffer =~ s/^(.*)\n//;
   }
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

$loop->loop_once until defined $glib_line and defined $ioasync_line;

is( $glib_line,    "Hello world!", 'Glib read' );
is( $ioasync_line, "Hello world!", 'IO::Async read' );

done_testing;
