#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Resolver::DNS;

my $loop = IO::Async::Loop->new;
my $resolver = $loop->resolver;

$resolver->res_query(
   dname => $ARGV[0],
   type  => "SRV",
)->on_done( sub {
   my ( $pkt, @srvs ) = @_;

   foreach my $srv ( @srvs ) {
      printf "priority=%d weight=%d target=%s port=%d\n",
         @{$srv}{qw( priority weight target port )};
      if( my $addresses = $srv->{address} ) {
         printf "  address=%s\n", $_ for @$addresses;
      }
      else {
         print "  address unknown\n";
      }
   }
})->get;
