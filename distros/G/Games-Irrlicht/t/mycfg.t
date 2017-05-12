#!/usr/bin/perl -w

# test config file reading

use Test::More tests => 41;
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

my $options = { config => 'config/test.cfg', disable_log => 1 };
my $app = Games::Irrlicht::MyApp->new( $options );

is (keys %$app, 2, 'data all encapsulated');
is (exists $app->{_app}, 1, 'data all encapsulated');
is (exists $app->{myfps}, 1, 'data all encapsulated');

# check test.cfg config
is ($app->option('fullscreen'), 0, 'windowed');
is ($app->option('title'), 'Test2', 'Test2');
is ($app->option('width'), 320, 'width');
is ($app->option('height'), 200, 'height');
is ($app->option('depth'), 16, 'depth');
is ($app->option('resizeable'), 0, 'rsizeable');
is ($app->option('renderer'), 'OpenGL', 'useopengl');
is ($app->option('max_fps'), 15, 'max_fps');
is ($app->option('time_warp'), '2.1', 'time_warp');
is ($app->option('useconsole'), '1', 'useconsole');
is ($app->option('showfps'), '1', 'showfps');

##############################################################################
$app = Games::Irrlicht::MyApp->new( disable_log => 1 );

is (keys %$app, 2, 'data all encapsulated');
is (exists $app->{_app}, 1, 'data all encapsulated');
is (exists $app->{myfps}, 1, 'data all encapsulated');

# check config (default config)
is ($app->option('fullscreen'), 0, 'windowed');
is ($app->option('title'), 'Test', 'Test');
is ($app->option('width'), 640, 'width');
is ($app->option('height'), 480, 'height');
is ($app->option('depth'), 16, 'depth');
is ($app->option('resizeable'), 1, 'rsizeable');
is ($app->option('max_fps'), 25, 'max_fps');
is ($app->option('time_warp'), 1, 'time_warp');
is ($app->option('useconsole'), '0', 'useconsole');
is ($app->option('showfps'), '0', 'showfps');

##############################################################################
$app = Games::Irrlicht::MyApp->new(config => 'non-existant', disable_log => 1);

is (keys %$app, 2, 'data all encapsulated');
is (exists $app->{_app}, 1, 'data all encapsulated');
is (exists $app->{myfps}, 1, 'data all encapsulated');

# check config
is ($app->option('fullscreen'), 0, 'windowed');
is ($app->option('title'), 'Games::Irrlicht', 'name');
is ($app->option('width'), 800, 'width');
is ($app->option('height'), 600, 'height');
is ($app->option('depth'), 32, 'depth');
is ($app->option('resizeable'), 1, 'rsizable');
is ($app->option('max_fps'), 60, 'max_fps');
is ($app->option('time_warp'), 1, 'time_warp');

##############################################################################
$options = { config => 'config/test2.cfg', disable_log => 1 };
$app = Games::Irrlicht::MyApp->new( $options );

is ($app->option('bar_barfel'), 'abc', '[bar] read ok');
is ($app->option('foo_bazel'), 9, '[foo] read ok');
