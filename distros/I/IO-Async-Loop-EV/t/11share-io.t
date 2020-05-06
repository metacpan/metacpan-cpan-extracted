#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use EV;
use IO::Async::Loop::EV;
use IO::Async::Stream;

sub make_readable_handle
{
   pipe( my $reader, my $writer ) or die "Cannot pipe() - $!";

   syswrite $writer, "Hello world!\n" or die "Cannot syswrite - $!";

   return $reader;
}

my $loop = IO::Async::Loop::EV->new;

my $ev_line;

my $ev_buffer = "";
my $ev_handle = make_readable_handle;
my $w = EV::io $ev_handle, EV::READ, sub {
   sysread $ev_handle, $ev_buffer, 8192, length $ev_buffer;
   $ev_line = $1 if $ev_buffer =~ s/^(.*)\n//;
};

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

$loop->loop_once until defined $ev_line and defined $ioasync_line;

is( $ev_line,      "Hello world!", 'EV read' );
is( $ioasync_line, "Hello world!", 'IO::Async read' );

done_testing;
