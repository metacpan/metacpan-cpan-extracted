#!/usr/bin/perl 
use strict;
use warnings;

use Math::Telephony::ErlangC qw( average_wait_time );

$|++;
print 'traffic (Erlang): '; chomp( my $traffic = <STDIN> );
print 'servers (number): '; chomp( my $servers = <STDIN> );
print 'mean service time (seconds): '; chomp( my $mst = <STDIN> );

printf "for the input data, the average time waiting in queue is %.1fs\n",
   average_wait_time($traffic, $servers, $mst);
