#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;

use Hoobot;

# parent hoobot
my $hoobot = Hoobot->new;
isa_ok( $hoobot => 'Hoobot', 'Bare new Hoobot' );

# test nested hoobots
{
  my $hoobot1 = Hoobot->new; # a nested hoobot
  # already tested 'Bare new Hoobot'
  $hoobot1->hoobot( $hoobot );
  is( $hoobot1->hoobot => $hoobot, 'Set/get hoobot works' );
}

# also test the constructor
{
  my $hoobot1 = Hoobot->new(hoobot => $hoobot);
  isa_ok( $hoobot => 'Hoobot', "New Hoobot with parent" );
  is( $hoobot1->hoobot => $hoobot, 'Get hoobot works' );
}

# test get/set ua
require LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$hoobot->ua( $ua );
is( $hoobot->ua => $ua, "Set/get ua works");

# silently created ua
{
  my $hoobot1 = Hoobot->new;
  # already tested a bare new
  isa_ok( $hoobot1->ua => 'LWP::UserAgent', "UA silently created for us" );
}

# does it recurse?
{
  my $hoobot1 = Hoobot->new( hoobot => $hoobot );
  # already tested hoobot with parent
  is( $hoobot1->ua => $ua, "Get ua (recursive) works");
}

# test get/set host
$hoobot->host( 'http://another.host' );
is( $hoobot->host => 'http://another.host', "Set/get host works");

# does it recurse?
{
  my $hoobot1 = Hoobot->new( hoobot => $hoobot );
  # already tested hoobot with parent
  is( $hoobot1->host => 'http://another.host', "Get host (recursive) works");
}

# default without $ENV{HOOBOT_HOST}
{
  local $ENV{HOOBOT_HOST};
  my $hoobot1 = Hoobot->new;
  # already tested bare new
  is( $hoobot1->host => 'http://www.bbc.co.uk', "Fallback host works");
}

# $ENV{HOOBOT_HOST}
{
  local $ENV{HOOBOT_HOST} = 'http://another.host';
  my $hoobot1 = Hoobot->new;
  # already tested bare new
  is( $hoobot1->host => 'http://another.host', "Host from \%ENV works");
}

# Hoobot->page is *not* tested here
