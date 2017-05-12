#!/usr/bin/perl -w

use Test::More tests => 42;
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

can_ok ('Games::Irrlicht::MyApp', qw/ 
  new time_warp frames current_time lastframe_time now
  _init quit option fullscreen
  main_loop draw_frame _handle_events
  freeze_time thaw_time
  stop_time_warp_ramp
  ramp_time_warp
  _ramp_time_warp
  time_is_frozen
  time_is_ramping
  pause
  min_fps max_fps
  min_frame_time max_frame_time
  width height depth resize
  del_timer timers add_timer get_timer
  add_group
  save load
  _resized 
  _deactivated_thing _activated_thing
  del_thing
  in_fullscreen
  quit_handler resize_handler post_init_handler pre_init_handler
  get_clock set_clock clock_to_ticks
  screenshot
  /);

#  BUTTON_MOUSE_LEFT
#  BUTTON_MOUSE_RIGHT
#  BUTTON_MOUSE_MIDDLE
# update app
#  watch_event
#  add_button del_button
# add_event_handler del_event_handler

my $options = { 
 width => 640, height => 480, depth => 24, max_fps => 60, disable_log => 1 };

my $app = Games::Irrlicht::MyApp->new( $options );

is (keys %$app, 2, 'data all encapsulated');
is (exists $app->{_app}, 1, 'data all encapsulated');
is (exists $app->{myfps}, 1, 'data all encapsulated');

#$app->add_event_handler(SDL_KEYDOWN, SDLK_q, { });

my $timer = 0;
$app->add_timer(20, 1, 0, 0, sub { $timer++ } );

# can't test bpp, since that depends on X, not the app :/
#is ($app->depth(), 24, 'depth is 24 bit');
is ($app->width(), 640, 'width 640 pixel');
is ($app->height(), 480, 'width 480 pixel');

#my $button = $app->add_button(1,2,3,4);
#is (scalar keys %{$app->{_app}->{buttons}}, 1, '1 button');
#$app->del_button($button->{id});
#is (scalar keys %{$app->{_app}->{buttons}}, 0, '0 buttons');
#$button = $app->add_button(1,2,3,4);
#$app->del_button($button);
#is (scalar keys %{$app->{_app}->{buttons}}, 0, '0 buttons');

$app->main_loop();

is ($app->{myfps}->{quit_handler},1, 'quit_handler() run once');
is ($app->{myfps}->{pre_init_handler},1, 'pre_init_handler() run once');
is ($app->{myfps}->{post_init_handler},1, 'post_init_handler() run once');
is ($app->{myfps}->{drawcounter},100, 'drawn 100 frames');
is ($app->{myfps}->{now} == 0, 1, 'now was initialized to 0');
is ($app->{myfps}->{timer_fired}, 1, 'timer fired once');
is ($app->time_warp(), 1, 'time_warp is 1.0');
is ($app->time_is_frozen(), '', 'time is not frozen');
is ($app->time_is_ramping(), '', 'time is not ramping');
is ($app->timers(), 0, 'no timers running');

#is (scalar keys %{$app->{_app}->{event_handler}}, 2, 
#	'one handler plus one for resizeing');

is ($app->in_fullscreen(), 0, 'were in windowed mode');
is ($app->fullscreen(0), 0, 'already were in windowed mode');
is ($app->fullscreen(), 1, 'toggled fullscreen');
is ($app->fullscreen(1), 1, 'already fullscreen');
is ($app->in_fullscreen(), 1, 'really in fullscreen');
is ($app->fullscreen(0), 0, 'back to windowed mode');

is ($app->max_frame_time() > 1, 1, 'max_frame_time was set');
is ($app->min_frame_time() < 1000, 1, 'min_frame_time was set');

# we cap at 60 frames, so the framerate should not be over 65 (some extra due
# to timer inaccuracies) and not below 10
is ($app->current_fps() < 65, 1, 'fps < 65');
is ($app->current_fps() > 10, 1, 'fps > 10');
is ($app->min_fps() > 10, 1, 'min fps > 10');
is ($app->max_fps() < 65, 1, 'max fps < 10');

# test that adding timer really adds more of them
my $timer1 = $app->add_timer( 2000,1,200, 0, sub {});
is ($app->timers(), 1, '1 timer running');
my $timer2 = $app->add_timer( 2000,1,200, 0, sub {});
is ($app->timers(), 2, '2 timer running');

$app->del_timer($timer1);
is ($app->timers(), 1, '1 left');
$timer2 = $app->get_timer($timer2->id());
is (ref($timer2), 'Games::Irrlicht::Timer', 'got timer from id');
$app->del_timer($timer2->{id});
is ($app->timers(), 0, 'none left');

is ($app->current_time() > 0, 1, 'current time elapsed');
is ($app->now(), $app->current_time(), 'current time equals real time');
is ($app->now(), $app->lastframe_time(), 'current time equals lastframe time');

##############################################################################

is (scalar keys %$app, 2, 'data all encapsulated');
if (scalar keys %$app != 2)
  {
  print '# current keys: ', join(" ", keys %$app),"\n";
  }
is (exists $app->{_app}, 1, 'data all encapsulated');
is (exists $app->{myfps}, 1, 'data all encapsulated');

##############################################################################
# group clear

my $group = $app->add_group();
$group->add (
#  $app->add_button(1,2,3,4),
  $app->add_timer(20, 1, 0, 0, sub { $timer++ } ),
  #$app->add_event_handler(SDL_KEYDOWN, SDLK_q, { }),
  );
is ($group->members(), 1, 'three members signed up');
$group->clear();
is ($group->members(), 0, 'three members gone');

