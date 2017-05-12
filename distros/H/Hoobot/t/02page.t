#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;

use Hoobot;
use Hoobot::Page;

{
  my $page = Hoobot::Page->new;
  isa_ok( $page => 'Hoobot::Page', 'Bare new Hoobot::Page' );
  isa_ok( $page => 'Hoobot', 'Also a Hoobot' );
}

{
  my $hoobot = Hoobot->new; # Hoobot tested elsewhere (not Hoobot->page)
  my $page = $hoobot->page('abc');
  isa_ok( $page => 'Hoobot::Page', 'Created from Hoobot->page' );
  is( $page->hoobot => $hoobot, "Correct parent set" );
  is( $page->page => 'abc', "Correct page set" );
}
