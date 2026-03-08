#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event;
use Linux::Event::Listen;
use Linux::Event::Stream;

my $loop = Linux::Event->new;

Linux::Event::Listen->new(
  loop => $loop,
  host => '127.0.0.1',
  port => 3000,

  on_accept => sub ($loop, $client_fh, $peer, $listen) {

    my $stream = Linux::Event::Stream->new(
      loop       => $loop,
      fh         => $client_fh,
      codec      => 'line',
      on_message => sub ($stream, $line, $data) {

        # Echo a line-based protocol. "quit" closes the connection cleanly.
        $stream->write_message("echo: $line");
        $stream->close_after_drain if $line eq 'quit';
      },
    );
  },

  on_error => sub ($loop, $err, $listen) {
    warn "listener error ($err->{op}): $err->{error}\n";
  },
);

$loop->run;
