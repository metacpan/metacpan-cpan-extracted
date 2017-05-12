#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop::Epoll;

use IO::Async::Stream;
use IO::Async::Signal;

my $loop = IO::Async::Loop::Epoll->new();

$loop->add( IO::Async::Stream->new(
      read_handle => \*STDIN,
      on_read => sub {
         my ( $self, $buffref ) = @_;
         while( $$buffref =~ s/^(.*)\r?\n// ) {
            print "You said: $1\n";
         }
      },
) );

$loop->add( IO::Async::Signal->new(
      name => 'INT',
      on_receipt => sub {
         print "SIGINT, will now quit\n";
         $loop->loop_stop;
      },
) );

$loop->loop_forever();
