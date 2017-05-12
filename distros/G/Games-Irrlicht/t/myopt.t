#!/usr/bin/perl -w

# test command line parsing

use Test::More tests => 6;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Games::Irrlicht::MyApp');
  }

# simulate command line
@ARGV = qw/--fullscreen --width=800/;

my $app = Games::Irrlicht::MyApp->new( disable_log => 1 );

is (keys %$app, 2, 'data all encapsulated');
is (exists $app->{_app}, 1, 'data all encapsulated');
is (exists $app->{myfps}, 1, 'data all encapsulated');

# check config
is ($app->option('fullscreen'), 1, 'not windowed');
is ($app->option('width'), 800, 'width=800');

