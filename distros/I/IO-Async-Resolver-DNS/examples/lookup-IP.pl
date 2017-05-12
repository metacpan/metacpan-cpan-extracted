#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Resolver::DNS;

my $loop = IO::Async::Loop->new;
my $resolver = $loop->resolver;

my @tasks = map {
   my $type = $_;

   $resolver->res_query(
      dname => $ARGV[0],
      type  => $type,
   )->on_done( sub {
      my ( $pkt, @addrs ) = @_;

      foreach my $addr ( @addrs ) {
         printf "$type address=%s\n", $addr;
      }
   });
} qw( A AAAA );

$loop->await_all( @tasks );
