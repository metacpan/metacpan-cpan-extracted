#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use IPC::PerlSSH::Async;

my $loop = IO::Async::Loop->new();

my @hostnames = @ARGV or die "Pass a list of hostnames\n";

my $waitcount = 0;

foreach my $host ( @hostnames ) {
   my $ips = IPC::PerlSSH::Async->new(
      Host => $host,
   );

   $loop->add( $ips );

   $waitcount++;

   $ips->eval(
      code => "scalar localtime",
      on_result => sub {
         print "The time on $host is $_[0]\n";

         $waitcount--;
         $loop->loop_stop unless $waitcount;
      },
      on_exception => sub {
         print "Could not obtain time on $host - $_[0]\n";

         $waitcount--;
         $loop->loop_stop unless $waitcount;
      },
   );
}

$loop->loop_forever;
