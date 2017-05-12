#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 5;

use Hoobot::Login;

{
  my $login = Hoobot::Login->new;
  isa_ok( $login => 'Hoobot::Login', 'Bare new Hoobot::Login' );
  isa_ok( $login => 'Hoobot::Page', 'Also a Hoobot::Page' );
  isa_ok( $login => 'Hoobot', 'And a Hoobot' );
}

{
  my $login = Hoobot::Login->new;
  $login->username( 'randomuser' );
  is( $login->username => 'randomuser', 'Get/set username' );
}

{
  my $login = Hoobot::Login->new;
  $login->password( 'randompass' );
  is( $login->password => 'randompass', 'Get/set password' );
}
