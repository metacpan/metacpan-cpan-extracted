#!/usr/bin/perl -w

# httpgate.pl
# the HTTPgate component

# see jrpchttp.xml

use strict;
use Jabber::RPC::HTTPgate;

my $gw = new Jabber::RPC::HTTPgate(
  server    => 'localhost:5700',
  identauth => 'jrpchttp.localhost:secret',
  httpcomp  => 'http',
);

$gw->start;
