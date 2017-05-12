
# Use Irrlicht (http://irrlicht.sf.net) in Perl

package Games::Irrlicht;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Config::Simple qw/-lc -strict/;
use Getopt::Long;

require DynaLoader;
require Exporter;

use vars qw/@ISA $VERSION @EXPORT_OK/;
@ISA = qw/Exporter DynaLoader/;

$VERSION = '0.04';

bootstrap Games::Irrlicht $VERSION;

use Games::Irrlicht::Constants;
use Games::Irrlicht::Thingy;
use Games::Irrlicht::Timer;
use Games::Irrlicht::Group;
use Games::Irrlicht::EventHandler qw/FPS_EVENT/;

##############################################################################

sub new
  {
  # create a new instance of Games::Irrlicht - usually you need only one
  my $class = shift;
  my $self = {}; bless $self, $class;

  $self->_init(@_);			# parse options
  $self->pre_init_handler();
  
  my $app = $self->{_app};
  my $opt = $app->{options};
 
  my $renderer = uc($opt->{renderer});
  
  {
    no strict 'refs';
    $renderer = &{'Games::Irrlicht::Constants::EDT_'.$renderer};
  }

  Games::Irrlicht->_init_engine( $renderer,
    $opt->{width}, $opt->{height}, $opt->{depth},
    $opt->{fullscreen}, $opt->{disable_log} );

  foreach my $k (qw/width height depth/)
    {
    $app->{$k} = $opt->{$k};
    }
  $app->{base_ticks} = $self->_get_ticks();

  $app->{now} = 0;
  $app->{start_time} = 0;			# for time_warp
  $app->{current_time} = 0;			# warped clock (current frame)
  $app->{lastframe_time} = 0;			# warped clock (last frame)
  $app->{clock} = { day => 0, hour => 0, minute => 0, second => 0, ms => 0 };
  $app->{console_open} = 0;			# console closed (or disabled)

  $self->post_init_handler();

  #if ($opt->{showfps})
  #  {
  #  $app->{fps_font} = $self->read_font_cfg($opt->{font_fps} || '');
  #  # 1 and 2 - left, 3 and 4 right
  #  $app->{fps_font}->align_x(Games::OpenGL::Font::2D::FONT_ALIGN_RIGHT()) 
  #    if $opt->{showfps} > 2;
  #  }

  #if ($opt->{useconsole})
  #  {
  ##  $app->{console_font} = $self->read_font_cfg($opt->{font_console} || '');
  #  my $class = 'Games::Console::OpenGL';
  #  $class = 'Games::Console::SDL' unless $opt->{useopengl};
  #  my $class_new = $class; $class =~ s/::/\//g; $class .= '.pm';
  #  require $class;
  #  # create new console with options from config file
  #  $opt->{console}->{font} = $app->{console_font};
  #  $app->{console} = $class_new->new( $opt->{console} );
  #  # and register it with our current size
  #  $app->{console}->screen_width($app->{width});
  #  $app->{console}->screen_height($app->{height});
  # }

  $self->message ('Application successfully initialized.');
  $self;
  }

sub getFileSystem
  {
  my $self = shift;
  $self;
  }

sub getOSOperator
  {
  my $self = shift;
  $self;
  }

sub getVideoDriver
  {
  my $self = shift;
  $self;
  }

sub getIrrlichtDevice
  {
  my $self = shift;
  $self;
  }

sub getSzeneManager
  {
  my $self = shift;
  $self;
  }

sub getGUIEnvironment
  {
  my $self = shift;
  $self;
  }

sub DESTROY
  {
  my $self = shift;

  $self->_done_engine();
  }

sub message
  { 
  my ($self,$msg) = @_; 

  my $app = $self->{_app};
  my $opt = $app->{options};
  #if ($opt->{useconsole})
  #  {
  #  $app->{console}->message(scalar localtime() . ' ' . $msg);
  #  }
  }

sub _init
  {
  my $self = shift;

  my $args;
  if (ref($_[0]) eq 'HASH')
    {
    $args = shift;
    }
  else
    {
    $args = { @_ };
    }
  $self->{_app} = {};
  my $app = $self->{_app};

  $app->{event_handler} = {};			# none yet

  $app->{options} = {};
  # if we have a config file, read it in, overwriting specified stuff
  my $cfg = Config::Simple->new();

  my $opt = $app->{options};
  # read() can fail:
  if ($cfg->read( $args->{config} || 'config/client.cfg'))
    {
    # The read-in config values will look like "default.FullScreen", so
    # normalize them and parse them
    my $hash = $cfg->vars();
    # sort makes App. appear before Input. so that debug is enabled before
    # binding the keys
    $opt->{debug} = 0;			# hard default to be sure
    $opt->{bindings} = {};
    my $watch = {};
    foreach my $k (sort keys %$hash)
      {
      my $key = lc($k);
      # section [App] or nothing
      if ($key =~ /^(app|default)\./)
        {
        $key =~ s/^\w+\.//;
	print "setting $key to $hash->{$k}\n" if $opt->{debug} > 1;
        $opt->{$key} = $hash->{$k};
        }
      # section [Input]
      # looks like "bind_event_0000 = 'a' or bind_event_quit = q
      elsif ($key =~ /^input\.bind_/)
        {
        $key =~ s/^input\.bind_event_//;
        my $char = $hash->{$k};
        if ($key =~ /^(fullscreen|quit|console|screenshot|pause|freeze)$/)
	  {
          $watch->{$key} = $char;
	  }
	else
	  {
          my ($type,$kind) = char2type_kind($char);
	  print "binding event $key to $hash->{$k} ($type, $kind)\n"
            if $opt->{debug} != 0;
          $opt->{bindings}->{$type}->{$kind} = $key;
	  }
        # so that we can look it up later
        $opt->{bound_to}->{$key} = $char;
        }
      elsif ($key =~ /^console\./)
        {
        # console config variables
        $key =~ s/^console\.//;
        $opt->{console}->{$key} = $hash->{$k};
        }
      else
        {
        $key =~ s/^(\w+)(\.)/$1_/;	# font.foo => font_foo
        $opt->{$key} = $hash->{$k};
        }
      }
    $self->watch_event( $watch ) if scalar keys %$watch != 0;
    }
  else
    {
    #warn ("Cannot find config file ".
    #      $args->{config} || 'config/client.cfg'.
    #	  ": $! \n");
    }

  # override config values with given options to new() 
  foreach my $key (keys %$args)
    {
    $opt->{lc($key)} = $args->{$key};
    }
  
  my $cmd = $self->_parse_command_line();
  foreach my $key (keys %$cmd)
    {
    $opt->{lc($key)} = $cmd->{$key} if defined $cmd->{$key};
    }

  # set some sensible defaults if neither config file nor arguments set them
  my $def = {
    width => 800,
    height => 600,
    depth => 32,
    fullscreen => 0,
    resizeable => 1,
    max_fps => 60,
    time_warp => 1,
    renderer => 'OpenGL',
    disable_log => 0,
    useconsole => 0,
    font_console => 'data/console.fnt',
    showfps => 0,
    font_fps => 'data/fps.fnt',
    title => 'Games::Irrlicht',
    debug => 0,
    config_sections => [],
    console_background_color => [0.2,0.4,0.9],
    console_background_alpha => 0.9,
    console_text_color => [0.8,0.8,1],
    console_text_alpha => 1,
    };
  foreach my $key (keys %$def)
    {
    $opt->{$key} = $def->{$key} 
      unless exists $opt->{$key} && defined $opt->{$key};
    }
  $opt->{config_sections} = [ $opt->{config_sections} ]
   unless ref $opt->{config_sections} eq 'ARRAY';
 
  # normalize flags 
  foreach my $key (qw/
     fullscreen resizeable useconsole debug disable_log
    /)
    {
    $opt->{$key} = 0 unless defined $opt->{$key};	# auto-vivify
    $opt->{$key} = 0 if $opt->{$key} =~ /^(0|off|no|false)$/i;
    # TODO: should really complain about typos
    $opt->{$key} = 1 if $opt->{$key} ne '0';
    }

  KEY:
   foreach my $key (keys %$opt)
    {
    next if $key =~ /^(bindings|bound_to|console|config)$/;
    foreach my $k (@{$opt->{config_sections}})
      {
      my $kk = quotemeta(lc($k)) . '_';
      next KEY if $key =~ /^$kk/;
      }
    warn ("Unknown key '$key' in options") unless exists $def->{$key};
    }

  $app->{in_fullscreen} = $opt->{fullscreen};	# started windowed?
  
  # limit to some sensible values
  $opt->{max_fps} = 500 if $opt->{max_fps} > 500;
  $opt->{max_fps} = 0 if $opt->{max_fps} < 0;
  $opt->{width} = 16 if $opt->{width} < 16;
  $opt->{height} = 16 if $opt->{height} < 16;
  $opt->{depth} = 8 if $opt->{depth} < 8;

#  $app->{event} = SDL::Event->new();		# create an event handler

  $app->{time_warp} = $opt->{time_warp};	# copy to modify it later

  # setup the framerate monitoring
  $app->{min_time} = 0;
  $app->{min_time} = 1000 / $opt->{max_fps} if $opt->{max_fps} > 0;
  # contains the FPS avaraged over the last second
  $app->{current_fps} = 0;
  $app->{frames} = 0;				# number of frames
  $app->{ramp_warp_target} = 0;			# disable ramping
  $app->{ramp_warp_time} = 0;			# disable ramping
  
  $app->{timers} = {};				# none yet

  $app->{next_timer_check} = 0;			# disable (always check)
  $app->{quit} = 0;				# no quit yet

#  if ($opt->{resizeable})
#    {
#    $self->add_event_handler( SDL_VIDEORESIZE, 0, \&_resized);
#    }
  $self;
  }

sub _parse_command_line
  {
  my $self = shift;

  my $cmd = {}; my $input = {};
  # override options with command line arguments
  foreach my $key (qw/
    fullscreen resizeable renderer useconsole showfps
    /)
    {
    $input->{"$key!"} = \$cmd->{$key};
    } 
  foreach my $key (qw/
    width height depth max_fps
    /)
    {
    $input->{"$key=i"} = \$cmd->{$key};
    } 
  foreach my $key (qw/
    name
    /)
    {
    $input->{"$key=s"} = \$cmd->{$key};
    } 

  my $rc = GetOptions ( %$input); 

  return {} unless $rc;
  $cmd;
  }

sub option
  {
  # get/set a specific option as it was originally set 
  my ($self,$key) = @_;

  my $app = $self->{_app};
  my $opt = $app->{options};
  my $org_key = $key;
  my $namespace = '';

  if ($key =~ /(.+)\./)
    {
    $namespace = $1;
    if (exists $opt->{$namespace} && ref($opt->{$namespace}) eq 'HASH') 
      {
      $opt = $opt->{$namespace}; $key =~ s/.+\.//;
      }
    else
      {
      return \"Error: Unknown option name space '$namespace'";
      }
    }

  if (!exists $opt->{$key})
    {
    return \"Error: Option '$org_key' does not exist";
    }

  if (@_ > 2)
    {
    if ($key eq 'max_fps')
      {
      $app->{min_time} = 0;
      $app->{min_time} = 1000 / $opt->{max_fps} if $opt->{max_fps} > 0;
      }
    if ($key eq 'fullscreen')
      {
      $app->{app}->fullscreen($opt->{$key}); return $opt->{fullscreen};
      }
    if ($key =~ /renderer/)
      {
      return \"Error: Attempt to modify read-only value '$key'";
      }
    my $val = $_[2]; $val = [ split /\s*,\s*/, $val ] if $val =~ /,/;
    if ($namespace ne '')
      {
      $app->{$namespace}->$key($val);
      }
    $opt->{$key} = $val;
    }
  return undef unless exists $opt->{$key};
  $opt->{$key};
  }

sub resize
  {
  my ($self,$w,$h) = @_;

  # can resize?
  return if $self->{_app}->{options}->{resizeable} == 0;

  my $app = $self->{_app};
  
  # XXX TODO: 
  # resize
  $app->{app}->resize($w,$h);
  # cache new size
  $app->{width} = $app->{app}->width();
  $app->{height} = $app->{app}->height();
  }

sub _resized
  {
  # called when the app was resized
  my ($self,$handler,$event) = @_;

  my $app = $self->{_app};
  my $opt = $app->{options};

  $app->{app}->resize($app->{width},$app->{height});

 # # register new height/widht with all our 2D fonts 
 # foreach my $font (@{$app->{fonts}})
 #   {
 #   $font->screen_width($app->{width});
 #   $font->screen_height($app->{height});
 #   }
 # if ($opt->{useconsole})
 #   {
 ##   $app->{console}->screen_width($app->{width});
 #   $app->{console}->screen_height($app->{height});
 #   }

  $self->resize_handler();
  }

sub width
  {
  my $self = shift;

  $self->{_app}->{width};
  }

sub height
  {
  my $self = shift;
  $self->{_app}->{height};
  }

sub depth
  {
  my $self = shift;
  $self->{_app}->{depth};
  }

#sub update
#  {
#  my $self = shift;
#  $self->{_app}->{app}->update(@_);
#  }

#sub app
#  {
#  my $self = shift;
#  $self->{_app}->{app};
#  }

sub in_fullscreen
  {
  # returns true for in fullscreen, false for in window
  my $self = shift;

  $self->{_app}->{in_fullscreen};
  }

sub fullscreen
  {
  # toggle the application into and out of fullscreen
  # if given an argument, and this is true, switches to fullscreen
  # if given an argument, and this is fals, switches to windowed
  # returns true for in fullscreen, false for in window
  my $self = shift;

  my $app = $self->{_app};
  if (@_ > 0)
    {
    my $t = shift || 0; $t = 1 if $t != 0;
    return $app->{in_fullscreen} if ($t == $app->{in_fullscreen});
    }
  $app->{in_fullscreen} = 1 - $app->{in_fullscreen};	# toggle
 # XXX TODO
#  $app->{app}->fullscreen();				# switch
  $app->{in_fullscreen};
  }

##############################################################################

sub add_group
  {
  my ($self) = @_;

  Games::Irrlicht::Group->new($self);
  }

##############################################################################

sub _deactivated_thing
  {
  # When a thing (timer, event handler, button etc) is deactivated, it
  # notifies the app by calling this routine with itself as argument
  my ($self,$thing) = @_;

  # do nothing for timers and buttons yet
  return unless ref($thing) && $thing->isa('SDL::App::FPS::EventHandler');

  # remove it from the group of handlers that will be checked, it will
  # still remain in the entire group
  my $id = $thing->{id};
  my $app = $self->{_app};
  my $type = $thing->{type};
  delete $app->{event_handler}->{$type}->{$id};                 # delete here
  }

sub _activated_thing
  {
  # When a thing (timer, event handler, button etc) is (re)activated, it
  # notifies the app by calling this routine with itself as argument
  my ($self,$thing) = @_;

  # do nothing for timers and buttons yet
  return unless ref($thing) && $thing->isa('Games::Irrlicht::EventHandler');

  # add it to the group of handlers that will be checked
  my $id = $thing->{id};
  my $app = $self->{_app};
  my $type = $thing->{type};
  $app->{event_handler}->{$type}->{$id} = $thing;               # add here
  }

##############################################################################
# timer stuff

sub add_timer
  {
  # add a timer to the list of timers
  # The timer fires the first time after $time ms, then after each $delay ms
  # for $count times. $count < 0 means fires infinity times. $callback must
  # be a coderef, which will be called when the timer fires
  my $self = shift;
  my ($time, $count, $delay, $rand, $callback, @args) = @_;

  my $app = $self->{_app};
  my $timer = Games::Irrlicht::Timer->new(
    $self, $time, $count, $delay, $rand, $app->{current_time}, $callback,
    @args);
  return undef if $timer->{count} == 0;         # timer fired once, and expired

  # otherwise remember it
  $app->{timers}->{$timer->{id}} = $timer;
  # comes before last timer?
  if ($app->{time_warp} > 0)
    {
    $app->{next_timer_check} = $timer->{next_shot} if
      $app->{next_timer_check} > $timer->{next_shot};
    }
  else
    {
    $app->{next_timer_check} = $timer->{next_shot} if
      $app->{next_timer_check} > $timer->{next_shot};
    }
  $app->{timer_modified} = 1;
  $timer;
  }

sub timers
  {
  # return amount of still active timers
  my $self = shift;

  return scalar keys %{$self->{_app}->{timers}};
  }

sub get_timer
  {
  # return ptr to a timer with id $id
  my ($self,$id) = @_;

  return unless exists $self->{_app}->{timers}->{$id};
  $self->{_app}->{timers}->{$id};
  }

sub del_timer
  {
  # delete a timer with a specific id
  my ($self,$id) = @_;

  $id = $id->{id} if ref($id) && $id->isa('Games::Irrlicht::Timer');

  my $app = $self->{_app};
  $app->{next_timer_check} = 0;         # disable (always check)
  $app->{timer_modified} = 1;
  delete $app->{timers}->{$id};
  }

sub _expire_timers
  {
  # check all timers for whether they have expired (need to fire) or not
  my $self = shift;

  my $app = $self->{_app};
  return 0 if scalar keys %{$app->{timers}} == 0;       # no timers?
  return 0 if $app->{time_warp} == 0;                   # time stands still

  $app->{timer_modified} = 0;                           # track add/del
  my $now = $app->{current_time};                       # timers are warped
  my $time_warp = $app->{time_warp};                    # timers are warped

  $app->{next_timer_check} = 0;                         # not known yet

  # check (active) timers for beeing due
  # actually, inactive timer will simple be not due
  my $due = []; my @delete = ();
  foreach my $id (keys %{$app->{timers}})
    {
    my $timer = $app->{timers}->{$id}; my $overdue;
    do {
      $overdue = $timer->is_due($now,$time_warp);       # let timer check
      if (defined $overdue)
        {
        # timer should have fired, so remember it and it's overdue value
        push @$due, [ $timer, $overdue ];
        # $app->{timer_modified} = 1 && delete $app->{timers}->{$id}
        $app->{timer_modified} = 1 && push (@delete, $id)
         if $timer->{count} == 0;               # remove any exhausted timer
        }
      # if timer's next shot would also be before $now, add it also
      } while (defined $overdue);
    # this timer will be due next time then:

    # this will also timers that do not fire again, since these set it to 1
    next if $app->{timer_modified} != 0;        # if disabled, don't bother

    # if not yet know, take at least this
    if ($app->{next_timer_check} == 0)
      {
      $app->{next_timer_check} = $timer->{next_shot};
      next;
      }
    if ($app->{time_warp} > 0)
      {
      $app->{next_timer_check} = $timer->{next_shot}
          if $timer->{next_shot} < $app->{next_timer_check};
      }
    else
      {
      $app->{next_timer_check} = $timer->{next_shot}
        if $timer->{next_shot} > $app->{next_timer_check};
      }
    }
  # fire due timers sorted on their overdue value
  foreach my $t (sort { $b->[1] <=> $a->[1] } @$due)
    {
    my $timer = $t->[0];
    $timer->fire($t->[1]);
    my $id = $timer->{id};

    }
  # remove any exhausted timer
  foreach my $id (@delete)
    {
    delete $app->{timers}->{$id};
    }

  $app->{next_timer_check} = 0                  # disable (always check)
    if $app->{timer_modified} != 0;
  }

##############################################################################
# time and clock functions

sub stop_time_warp_ramp
  {
  # disable time warp ramping when it is in progress (otherwise does nothing)
  my $self = shift;
  $self->{_app}->{ramp_warp_time} = 0;
  }

sub freeze_time
  {
  # stop the waped clock (by simple setting time_warp to 0)
  my $self = shift;

  my $app = $self->{_app};
  $app->{time_warp_frozen} = $app->{time_warp};
  $app->{time_warp} = 0;
  # disable ramping
  $app->{ramp_warp_time} = 0;
  }

sub time_is_frozen
  {
  # return true if the time is currently frozen
  my $self = shift;

  $self->{_app}->{time_warp} == 0;
  }

sub time_is_ramping
  {
  # return true if the time warp is currently ramping (changing)
  my $self = shift;

  $self->{_app}->{ramp_warp_time} != 0;
  }

sub thaw_time
  {
  # reset the time warp to what it was before unfreeze_time() was called, thus
  # re-enabling the clock. Does nothing when the clock is not frozen.
  my $self = shift;

  my $app = $self->{_app};
  return if $app->{time_warp} != 0;
  $app->{time_warp} = $app->{time_warp_frozen};
  # disable ramping
  $app->{ramp_warp_time} = 0;
  }

sub ramp_time_warp
  {
  # $target_factor,$time_to_ramp
  my $self = shift;

  my $app = $self->{_app};
  if (@_ == 0)
    {
    if ($app->{ramp_warp_time} == 0)	# ramp in effect?
      {
      return;				# no
      }
    else
      {
      return 
       ($app->{ramp_warp_target}, $app->{ramp_warp_time}, 
        $app->{time_warp}, $app->{ramp_warp_startwarp},
        $app->{ramp_warp_startime});
      }
    }
  # if target warp is already set, don't do anything
  return if $app->{time_warp} == $_[0];
 
  # else setup a new ramp
  ($app->{ramp_warp_target}, $app->{ramp_warp_time}) = @_;
  $app->{ramp_warp_time} = abs(int($app->{ramp_warp_time})); 
  $app->{ramp_warp_startwarp} = $app->{time_warp};
  $app->{ramp_warp_starttime} = $app->{now};
  $app->{ramp_warp_endtime} = $app->{now} + $app->{ramp_warp_time};
  $app->{ramp_warp_factor_diff} = 
   $app->{ramp_warp_target} - $app->{time_warp};
  }

sub _ramp_time_warp
  {
  # do the actual ramping by computing a new time warp at start of frame
  my $self = shift;

  my $app = $self->{_app};
  # no ramping in effect?
  return if $app->{ramp_warp_time} == 0;

  # if we passed the end time, stop ramping
  if ($app->{now} >= $app->{ramp_warp_endtime})
    {
    $app->{ramp_warp_time} = 0;
    $app->{time_warp} = $app->{ramp_warp_target};
    }
  else
    {
    # calculate the difference between now and the start ramp time
    # 600 ms from 1000 ms elapsed, diff is 2, so we have 2 * 600 / 1000 => 1.2
    $app->{time_warp} = 
     $app->{ramp_warp_startwarp} + 
      ($app->{now} - $app->{ramp_warp_starttime}) *
       $app->{ramp_warp_factor_diff} / $app->{ramp_warp_time}; 
    }
  }

sub time_warp
  {
  # get/set the current time_warp, e.g. the factor how fast the time passes
  # the time_warp will be effective from the next frame onwards
  my $self = shift;

  my $app = $self->{_app};
  if (@_ > 0)
    {
    $app->{time_warp} = shift;			# set new value
    $app->{ramp_warp_target} = 0;		# disable ramping
    $app->{ramp_warp_time} = 0;			# disable ramping
    }
  $app->{time_warp};
  }

sub start_time
  {
  # get the time when the app started in ticks
  my $self = shift;
  
  $self->{_app}->{start_time};
  }

sub now
  {
  # return current time at the start of the frame in ticks, unwarped.
  my $self = shift;

  $self->{_app}->{now};
  }

sub current_time
  {
  # return current time at the start of the frame. This time will be warped
  # by time_warp, e.g a time_warp of 2 makes it go twice as fast as now().
  # Note that the returned value will only change at the start of each frame.
  my $self = shift;

  $self->{_app}->{current_time};
  }

sub lastframe_time
  {
  # return (warped) time at the start of the last frame. See current_time().
  my $self = shift;

  $self->{_app}->{lastframe_time};
  }

sub get_clock
  {
  # return the (warped) current time in days, hours, minutes, seconds and ms
  my $self = shift;

  my $ct = $self->{_app}->{current_time};
  my $clock = $self->{_app}->{clock};

  ((int($ct / (24 * 3600000))) + $clock->{day},
   (int($ct / 3600000) % 24) + $clock->{hour},
   (int($ct / 60000) % 60) + $clock->{minute},
   (int($ct / 1000) % 60) + $clock->{second},  
   $ct % 1000 + $clock->{second});  
  }

sub set_clock
  {
  # set the (warped) current time to equal days, hours, minutes, seconds and ms
  my ($self,$day,$hour,$minute,$second,$ms) = @_;
  
  my $clock = $self->{_app}->{clock};

  $clock->{day} = $day if defined $day;
  $clock->{hour} = $hour if defined $hour;
  $clock->{minute} = $minute if defined $minute;
  $clock->{second} = $second if defined $second;
  $clock->{ms} = $ms if defined $ms;
  }

sub clock_to_ticks
  {
  # return time given as days, hours, minutes, seconds and ms (as difference
  # e.g. not related to current time) as tick count.
  my ($day,$hour,$minute,$second,$ms) = @_;
  
  ($ms||0) + ($second||0) * 1000 + ($minute||0) * 60000 +
  ($hour||0) * 3600000 + 
  ($day||0) * 24 * 3600000;
  }

##############################################################################
# deletes a timer, event handler or button, depending on the type of object
# passed as argument

sub del_thing
  {
  my ($self,$obj) = @_;

  if (!ref($obj))
    {
    require Carp;
    Carp::croak ("Need an object reference for del()");
    }
  if ($obj->isa('Games::Irrlicht::Timer'))
    {
    $self->del_timer($obj);
    }
  elsif ($obj->isa('Games::Irrlicht::EventHandler'))
    {
    $self->del_event_handler($obj);
    }
  else
    {
    require Carp;
    Carp::croak ("Need a timer or event handler for del()");
    }
  }

##############################################################################

sub current_fps
  {
  # return current number of frames per second, averaged over the last 1000ms
  my $self = shift;

  $self->{_app}->{current_fps};
  }

sub hide_mouse_cursor
  {
  my ($self,$vis) = @_;

  $self->setVisible($vis); 
  }

sub frames
  {
  # return number of frames already drawn
  my $self = shift;

  $self->{_app}->{frames};
  }

sub _handle_events
  {
  # handle all events (actually, only handles QUIT event, the rest are
  # handled by the called event handlers), return true if QUIT occured,
  # otherwise false)
  my $self = shift;

  my $done = 0;
  my $app = $self->{_app};
  my $opt = $app->{options};
  my $event = $app->{event};
  $app->{handled_events} = 0;                   # count handled ones

  # inner while to handle all events, not only one per frame
  #$event->set_key_repeat(250,20);               # TODO seems not to work?

  return 0;

  while ($event->poll())                        # got one event?
    {
    $app->{handled_events}++;                   # count 'em
#    return 1 if $event->type() == SDL_QUIT;     # check this first

    my $type = $event->type();
    my $k = $event->key_sym();

#    if ($type != SDL_KEYDOWN && $type != SDL_KEYUP)
#      {
#      # SDL uses 1,2,3,4,5; we use 1,2,4,8,16 to beeing able to watch more than
#      # one button at the same time
#      $k = 2 ** ($event->button() - 1);
#      }

#    # if console is open, catch events for it first
#    next if $app->{console_open} &&
#     $self->_console_event($type,$k,$event->key_mod(),$event);

    # if user-defined bindings exists
    if (exists $opt->{bindings}->{$type}->{$k})
      {
      $k = $opt->{bindings}->{$type}->{$k};     # name like 'event_slow_down'
      $type = FPS_EVENT;
      }

    # Check event with all registered active event handlers, the foreach loop
    # uses (internaly) a copy of keys, so that deleting/adding keys
    # will not change the list of checked event handler while we loop over
    # them. This is necc. lest some handler activates another handler, which
    # should not checked this time, or deactivates some, which *should* be
    # checked this time. (e.g. (de)activation counts only in the next frame)

    # check only active ones of the right type
    my $handler = $app->{event_handler}->{$type};
    # but use the global hash to access them
    my $handlers = $app->{event_handlers};
    foreach my $h (keys %$handler)
      {
      $handlers->{$h}->check($event,$type,$k);
      }

#    next if $type != SDL_MOUSEBUTTONDOWN && $type != SDL_MOUSEBUTTONUP &&
#            $type != SDL_MOUSEMOTION;

#    # for all active buttons, do the same
#    my $buttons = $app->{buttons};
#    my @active = ();
#    foreach my $id (keys %$buttons)
#      {
#      push @active, $buttons->{$id} if $buttons->{$id}->is_active();
#      }
#    foreach my $b (@active)
#      {
#      $b->check($event,$type);
#      }

    }
  $done + $app->{quit};         # terminate if an event handler/button set it
  }

sub _next_frame
  {
  my $self = shift;
  
  my $app = $self->{_app};
  $app->{frames}++;				# one more
  
  # get current time at start of frame, and wait a bit if we are too fast
  my $diff; 
  ($app->{now},$diff,$app->{current_fps}) = 
    _delay( $app->{min_time}, $app->{base_ticks});

  # advance our clock warped by time_warp
  $app->{current_time} =
    $app->{time_warp} * $diff + $app->{lastframe_time};
  $self->_ramp_time_warp() if $app->{ramp_warp_time} != 0;

#  print "$app->{current_time}\n";

  # now do something that takes time, like updating the world and drawing it
  $self->draw_frame(
   $app->{current_time},$app->{lastframe_time},$app->{current_fps});

  my $rc = $self->_run_engine();
  $self->quit() unless $rc;

  my $opt = $app->{options};
#  $app->{console}->render($app->{current_time}) if $opt->{useconsole};
#  $self->_show_fps() if $opt->{showfps};

  $app->{lastframe_time} = $app->{current_time};
  }  

sub quit
  {
  # can be called to quit the application
  my $self = shift;

  $self->{_app}->{quit} = 1;		# make next _handle_events() quit
  }

sub pause
  {
  # can be called to let the application to wait for the next event or a
  # specific event type (even a list)
  my $self = shift;

  my $app = $self->{_app};
  if (@_ == 0)
    {
    $app->{event}->wait();
    }
  else
    {
    my $type;
    while ($app->{event}->wait())
      {
      $type = $app->{event}->type();
      #if ($type == SDL_QUIT)			# don't ignore this one
      #  {
      #  $app->{quit} = 1; last;			# quit ASAP
      #  }
      foreach my $t (@_)
        {
        return if $t == $type;
        }
      }
    }
  }

sub main_loop
  {
  my $self = shift;

  # TODO:
  # don't call _handle_events() when there are no events? Does this matter?
  my $app = $self->{_app};
  while (!$app->{quit} && $self->_handle_events() == 0)
    {
    if (scalar keys %{$app->{timers}} > 0)			# no timers?
      {
      if ($app->{time_warp} > 0)
        {
        $self->_expire_timers() 
         if (($app->{next_timer_check} == 0) ||
            ($app->{current_time} >= $app->{next_timer_check}));
        }
      else
        {
        $self->_expire_timers() 
         if (($app->{next_timer_check} == 0) ||
           ($app->{current_time} <= $app->{next_timer_check}));
        }
      }
    $self->_next_frame();		# update the screen and fps monitor
    }
  $self->quit_handler();
  }

##############################################################################

sub screenshot
  {
  my $self = shift;

  my $app = $self->{_app};
  require File::Spec;

  my $path = shift || File::Spec->curdir();
  my $name = shift;

  if (!defined $name)
    {
    # find first free name
    $name = $app->{screenshot_name} || 'screenshot0000';
    $name++ while (-e File::Spec->catfile($path,$name.'.bmp'));
    $app->{screenshot_name} = $name; $app->{screenshot_name}++;
    }
  $name .= '.bmp' unless $name =~ /\.bmp$/;
  my $filename = File::Spec->catfile($path,$name);

  # XXX TODO
  if ($app->{options}->{useopengl})
    {
    my $w = $app->{width};
    my $h = $app->{height};
#    my $data = SDL::OpenGL::glReadPixels (0,0,$w,$h,
#      SDL::OpenGL::GL_BGR(),
#      SDL::OpenGL::GL_UNSIGNED_BYTE());
#    SDL::OpenGL::SaveBMP( $filename, $w, $h, 24, $data);
    }
  else
    {
#    SDL::SaveBMP( $app->{app}, $filename );
    }
  }


sub load
  {
  my ($self,$sig,$version,$file) = @_;
  
  my $load = Storable::lock_retrieve($file);
  return (undef, "Error retrieving data from '$file'") if !defined $load;

  if (!exists $load->{self} || $load->{sig} !~ /^Games::Irrlicht::/)
    {
    return (undef, "'$file' doesn't contain a properly saved state");
    }
  if (!exists $load->{sig} || $load->{sig} !~ /^$sig/)
    {
    return (undef, "'$file' is not a properly saved state");
    }
  if (!exists $load->{ver} || $load->{ver} > $version)
    {
    return (undef, "'$file' can only be read with v$version or newer");
    }
  my $data = $load->{data};

  # overwrite our own data with the saved version
  $self->{app} = $load->{data};
  
  # fake time to be what it was when we saved
  # XXX TODO huh?
  $self->{_app}->{base_ticks} = $self->_get_ticks();
  return ($data,undef);
  }

sub save
  {
  my ($self,$sig,$min_version,$file,$data) = @_;

  Storable::lock_store( {
   self => 'Games::Irrlicht::$VERSION',
   sig => $sig,
   ver => $min_version,
   app => $self->{app},
   data => $data 
   }, $file);
  }

##############################################################################
##############################################################################
# routines that are usually overriden in a subclass

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;
 
  $self; 
  }

sub post_init_handler
  {
  $_[0];
  }

sub pre_init_handler
  {
  $_[0];
  }

sub quit_handler
  {
  $_[0];
  }

sub resize_handler
  {
  $_[0];
  }

1;

__END__

=pod

=head1 NAME

Games::Irrlicht - use the Irrlicht 3D Engine in Perl

=head1 SYNOPSIS

	package MyGame;
	use strict;

	use base Games::Irrlicht;

	use Games::Irrlicht::Constants;		 get EDT_SOFTWARE etc

	# override methods:

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

=head2 The Why

When building a game or screensaver displaying some continously running
animation, a couple of basics need to be done to get a smooth animation and
to care of copying with varying speeds of the system. Ideally, the animation
displayed should be always the same, no matter how fast the system is.

This not only includes different systems (a PS/2 for instance would be slower
than a 3 Ghz PC system), but also changes in the speed of the system over
time, for instance when a background process uses some CPU time or the
complexity of the scene changes.

In many old (especial DOS) games, like the famous Wing Commander series, the
animation would be drawn simple as fast as the system could, meaning that if
you would try to play such a game on a modern machine it we end before you
had the chance to click a button, simple because it wizzes a couple 10,000
frames per second past your screen.

While it is quite simple to restrict the maximum framerate possible, care
must be taken to not just "burn" surplus CPU cycles. Instead the application
should free the CPU whenever possible and give other applications/thread
a chance to run. This is especially important for low-priority applications
like screensavers.

C<Games::Irrlicht> makes this possible for you without you needing to worry
about how this is done. It will restrict the frame rate to a possible maximum
and tries to achive the average framerate as close as possible to this
maximum.

C<Games::Irrlicht> also monitors the average framerate and gives you access
to this value, so that you can, for instance, adjust the scene complexity
based on the current framerate. You can access the current framerate,
averaged over the last second (1000 ms) by calling L<current_fps>.

=head2 Frame-rate Independend Clock

Now that our application is drawing frames (via the method L<draw_frame>,
which you should override in a subclass), we need a method to decouple the
animation speed from the framerate.

If we would simple put put an animation step every frame, we would get some
sort of Death of the Fast Machine" effect ala Wing Commander. E.g. if the
system manages only 10 FPS, the animation would be slower than when we do
60 FPS.

To achive this, C<SDL::App::FPS> features a clock, which runs independed of
the current frame rate (and actually, independend of the system's clock, but
more on this in the next section).

You can access it via a call to L<current_time>, and it will return the ticks
e.g. the number of milliseconds elapsed since the start of the application.

To effectively decouple animation speed from FPS, get at each frame the
current time, then move all objects (or animation sequences) according to
their speed and display them at the location that matches the time at the
start of the frame. See examples/ for an example on how to do this.

Note that it is better to draw all objects according to the time at the start
of the frame, and not according to the time when you draw a particular object.
Or in other words, treat the time like it is standing still when drawing a
complete frame. Thus each frame becomes a snapshot in time, and you don't get
nasty sideeffects like one object beeing always "behind" the others just
because it get's drawn earlier.

=head2 Time Warp

Now that we have a constant animation speed independend from framerate
or system speed, let's have some fun.

Since all our animation steps are coupled to the current time, we can play
tricks with the current time.

The function L<time_warp> let's you access a time warp factor. The default is
1.0, but you can set it to any value you like. If you set it, for instance to
0.5, the time will pass only half as fast as it used to be. This means
instant slow motion! And when you really based all your animation on the
current time, as you should, then it will really slow down your entire
game to a crawl.

Likewise a time warp of 2 let's the time pass twice as fast. There are
virtually no restrictions to the time warp.

For instance, a time warp greater than one let's the player pass boring
moments in a game, for instance when you need to wait for certain events in
a strategy game, like your factory beeing completed.

Try to press the left (fast forward), right (slow motion) and middle (normal)
mousebuttons in the example application and watch the effect.

If you are very bored, press the 'b' key and see that even negative time warps
are possible...

=head2 Ramping Time Warp

Now, setting the time war to factor of N is nice, but sometimes you want to
make dramatic effects, like slowly freezing the time into ultra slow motion
or speeding it up again.

For this, L<ramp_time_warp> can be used. You give it a time warp factor you
want to reach, and a time (based on real time, not the warped, but you can
of course change this). Over the course of the time you specified, the time
warp factor will be adapted until it reaches the new value. This means it
is possible to slowly speeding up or down.

You can also check whether the time warp is constant or currently ramping
by using L<time_is_ramping>. When a ramp is in effect, call L<ramp_time_warp>
without arguments to get the current parameters. See below for details.

The example application uses the ramping effect instead instant time warp.

=head2 Event handlers

This section describes events as external events that typically happen due
to user intervention.

Such events are keypresses, mouse movement, mouse button presses, or just
the flipping of the power switch. Of course the last event cannot be handled
in a sane way by our framework :)

All the events are checked and handled by Games::Irrlicht automatically. The
event QUIT (which denotes that the application should shut down) is also
carried out automatically. If you want to do some tidying up when this
happens, override the method L<quit_handler>.

The event checking and handling is done at the start of each frame. This
means no event will happen while you draw the current frame. Well, it will
happen, but the action caused by that event will delayed until the next
frame starts. This simplifies the frame drawing routine tremendously, since
you know that your world will be static until the next frame.

To associate an event with an action, you use the L<add_event_handler> method.
This method get's an event kind (like KEYDOWN or MOUSEBUTTONDOWN) and an
event type (like SPACE). When this specific event is encountered, the
also given callback routine is called. In the simplest form, this would be
an anonymous subroutine. Here is an example:

	my $handler = $app->add_event_handler ( KEYDOWN, SPACE, sub {
	  my ($self) = shift;
	  $self->pause(KEYDOWN);
	} );

This would pause the game until any key is pressed.

You can easily reconfigure the event to trigger for a different key like this:

	$handler->rebind( KEYDOWN, KEY_p );

If you want the same event to be triggered by different external events, then
simple add another event:

	my $handler2 = $app->add_event_handler ( KEYDOWN, KEY_P, sub {
	  my ($self) = shift;
	  $self->pause();
	} );

This would also alow the user to pause with 'P'.

Event bindings can also be removed with L<del_event_handler()>, if so desired.

See L<add_event_handler()> for more details.

=head2 Timers

Of course not always should all things happen instantly. Sometimes you need
to delay some events or have them happening at regular or irregular
intervalls again.

For these cases, C<SDL::App::FPS> features timers. These timers are different
from the normal SDL::Timers in that they run in the application clock space,
e.g. the time warp effects them. So if you application is in slow motion,
the events triggers by the timers will still happen at the correct time.

=head2 Asyncronous Timers

There are still some things that need a (near) real-time response and can not
wait for the next frame drawn. For instance when one music piece ends and the
next needs to be faded in, it would be unfortunate to wait until the next
frame start, which might come a bit late.

In these cases you can still use the normal system or Irrlicht timers, of
course.

=head1 SUBCLASSING

C<Games::Irrlicht> encapsulates any of it's private data under the key C<_app>.
So you can use any hash key other than C<_app> to store you data, no need
to encapsulate it further unless you plan on making your class sub-classable,
too.

When adding subroutines to your subclass, prefix them with something unique,
like C<__> or C<_myapp_> so that they do not interfere with changes in this
base class.

Do not access the data in the baseclass directly, always use the accessor
methods!

=head1 METHODS

The following methods should be overridden to make a usefull application:

=over 2

=item draw_frame()

Responsible for drawing the current frame. It's first two parameters are the
time (in ticks) at the start of the current frame, and the time at the
start of the last frame. These times are warped according to C<time_warp()>,
see there for an explanation on how this works.

The third parameter is the current framerate, averaged. You can use this to
reduce dynamically the complexity of the scene to achieve a faster FPS if it
falls below a certain threshold.

=back

The following methods can be overriden if so desired:

=over 2

=item pre_init_handler()

Called by L<new()> just before the creation of the application and window.

=item post_init_handler()

Called by L<new()> just after creating the window.

=item quit_handler()

Called by L<main_loop()> just before the application is exiting.

=item resize_handler()

Called automatically whenever the application window size changed.

=back

=head2 Irrlicht Special Methods

The following methods are special to Irrlicht and can be used to get
the single elements from the Irrlicht engine. With these you can then
call all Irrlicht functions like:

	my $driver = $app->VideoDriver();
	$driver->getPrimitiveCountDrawn();

These generally corrospondent to the Irrlicht API. See Irrlicht itself
for more information about available methods.

You can get the Irrlicht enums and constants by:

	use Games::Irrlicht::Constants;

This will export EDT_OPENGL etc into your namespace, where you can just use
them like in C++.

=over 2

=item getIrrlichtDevice

Returns the main irrlicht device class, C<IrrlichtDevice>.

=item getVideoDriver

Returns the video driver class, C<IVideoDriver>.

=item getSzeneManager

Returns the szene manager class.

=item getFileSystem

Returns the Irrlicht file system class.

=item getGUIEnvironment

Returns the Irrlicht GUI Environment class.

=item getOSOperator

Returns the Irrlicht OSOperator class.

=back

The following methods can be used, but need not be overriden except in very
special cases:

=over 2

=item new()

	$app = Games::Irrlicht->new($options);

Create a new application, init the Irrlicht subsystem, create a window, starts
the frame rate monitoring and the application time-warped clock.

new() gets a hash ref with options, the following options are supported:

	width		the width of the application window in pixel
	height		the width of the application window in pixel
	depth		the depth of the screen (colorspace) in bits
	max_fps		maximum number of FPS to do (save CPU cycles)
	resizeable	when true, the application window will be resizeable
			You should install an event handler to watch for
		        events of the type VIDEORESIZE.
	renderer	type of renderer. The following are possible:
			  OpenGL
			  DirectX8
			  DirectX9
			  Software
			  Null
	config		Path and name of the config file, defaults to
			  'config/client.cfg'.
	time_warp	Defauls to 1.0 - initial time warp value.
	fullscreen	0 = windowed, 1 - fullscreen
	title		Name of the app, will be the window title
	useconsole	enable a console (which can be shown/hidden)
	showfps		print fps (0 - disable, 1 upper-left, 2 lower-left,
                         3 lower-right, 4 upper-right corner)
	font_fps	name of the .fnt file containing the config for the
                        font for the FPS
	font_console	name of the .fnt file containing the config for the
			 font for the Console
	debug		0: disable, 1 (or higher for more): print debug info

C<useconsole> and C<showfps> do currently not work.

C<new()> also parses the command line options via Getopt::long, meaning that

	./app.pl --fullscreen --width=800 --noresizeable

will work as intended. If you want to prevent command line parsing, simple
clear C<@ARGV = ()> before calling new().

Please note that, due to the resulution of the timer, the maximum achivable FPS
with capping is about 200-300 FPS even with an empty draw routine. Of course,
my machine could do about 50000 FPS; but then it hogs 100% of the CPU. Thus
the framerate capping might not be accurate and cap the rate at a much lower
rate than you want. However, only C<max_fps> > 100 is affected, anything below
100 works usually as intended.

Set C<max_fps> to 0 to disable the frame-rate cap. This means the app will
burn all the CPU time and try to achive as much fps as possible. This is
not recommended except for benchmarking!

=item save

	$app->save($additional_data);

Saves the application state to a file. C<$additional> data can contain a
reference to additional data that will also be saved. See also L<load()>.

=item load

	($data,$error) = $app->load();

Loads the application state from a file. If additional data was passed to
L<save()>, then C<$data> will contain a references to this data afterwards.
C<$error> will contain any error that might occur, or undef.

=item screenshot

	$app->screenshot($path,$filename);

Save a screenshot in BMP format of the current surface to a file.

C<$path> and C<$filename> are optional, default is the current directory and
filenames named like 'screenshot_0000.bmp'. The first non-existing filename
will be used if C<$filename> is undef, otherwise the caller is responsible
for finding a free filename.

=item main_loop()

	$app->main_loop();

The main loop of the application, only returns when a QUIT event occured,
or $self->quit() was called.

=item quit()

	$self->quit();

Set a flag to quit the application at the end of the current frame. Can be
called in L<draw_frame()>, for instance.

=item is_fullscreen()

        if ($app->is_fullscreen())
          {
          }

Returns true if the application is currently in fullscreen mode.

=item width()

	my $w = $self->width();

Return the current width of the application's surface.

=item height()

	my $w = $self->height();

Return the current height of the application's surface.

=item depth()

	my $w = $self->depth();

Return the current bits per pixel of the application's surface in bits, e.g.
8, 16, 24 or 32.

=item add_timer()

	$app->add_timer($time,$count,$delay,$callback, @args ]);

Adds a timer to the list of timers. When time is 0, the timer fires
immidiately (calls $callback). When the count was 1, and time 0, then
the timer will not be added to the list (it already expired) and undef will be
returned. Otherwise the unique timer id will be returned.

C<@args> can be empty, otherwise the contents of these will be passed to the
callback function as additional parameters.

The timer will fire for the first time at C<$time> ms after the time it was
added, and then wait C<$delay> ms between each shot. if C<$count> is positive,
it gives the number of shots the timer fires, if it is negative, the timer
will fire endlessly until it is removed.

The timers added via add_timer() are coupled to the warped clock.

=item del_timer()

        $app->del_timer($timer);
        $app->del_timer($timerid);

Delete the given timer (or the one by the given id).

=item timers()

Return count of active timers.

=item hide_mouse_cursor()

	$self->hide_mouse_cursor( $vis );

Hides the mouse cursor if C<$vis> is true.

=item add_group()

        $group = $app->add_group();

Convienence method to create a new SDL::App::FPS::Group and bind it to this
application. Things (like timers) can be grouped together into groups and
thus can be enabled, deleted etc. in batches more easily.

=item option()

	print $app->option('max_fps'),"\n";	# get
	$app->option('max_fps',40);		# set to 40

Get/sets an option defined by the key (name) and an optional value. The name
space should be prepended with an underscore, like:

	print @{ $app->option('console_background_color') },"\n";

=item freeze_time_warp_ramp()

        $app->freeze_time_warp_ramp();

Disables any ramping of the time warp that might be in effect.

=item freeze_time()

        $app->freeze_time();

Sets the time warp factor to 0, effectively stopping the warped clock. Note
that the real clock still ticks and frames are still drawn, so you can overlay
some menu/animation over a static (froozen in time) background. Of course it
might be more efficient to save the current drawn frame as image and stop
the drawing if the not-changing background altogether.

=item thaw_time()

        $app->thaw_time();

Sets the time warp factor back to what it was before L<freeze_time()> was
called. Does nothing when the clock is not frozen.

=item ramp_time_warp

        $app->ramp_time_warp($target_factor,$time_to_ramp);

Set a tagret time warp factor and a time it will take to get to this factor.
The time warp (see L<time_warp()>) will then be gradually adjusted to the
target factor. C<$time_to_ramp> is in ms (aka 1000 == one second).

It is sometimes a good idea to read out the current time warp and ramp it to
a specific factor, like so:

        $time_warp = $app->time_warp();
        $app->ramp_time_warp($time_warp * 2, 1000);

But you need to restrict this somehow, otherwise the clock might be speed up
or slowed down to insanely high or low speeds. So sometimes it is just better
to do this:

        sub enable_slow_motion
          {
          # no matter how fast clock now is, slow it down to a fixed value
          $app->ramp_time_warp(0.5, 1000);
          }

When ramp_time_warp() is called without arguments, and ramping is in effect,
it returns a list consisting of:

        target factor           # to where we ramp
        time to ramp            # how long it takes (ticks)
        current time warp       # where are currently
        start time warp         # from where we ramp (factor)
        start time warp time    # from where we ramp (real time ticks)

When no ramping is in effect, it returns an empty list or undef.

You can disable/stop the time warping by setting a new time warp factor
directly like so:

	my $t = $app->time_warp(); $app->time_warp($t);

Or easier:

	$app->freeze_time_warp();

=item time_warp

	$app->time_warp(2);		# fast forward

Get or set the current time warp, e.g. the factor how fast the time passes.
The new time warp will be effective from the next frame onwards.

Please note that setting a time warp factor will disable time warp ramping.

=item time_is_ramping

	if ($app->time_is_ramping())
	  {
	  }

Returns true if the time warp factor is currently beeing ramped, e.g. chaning.

=item time_is_frozen

	if ($app->time_is_frozen())
	  {
	  }

Return true if the time is currently frozen, e.g. the clock is standing still.

=item frames()

Return number of frames drawn since start of app.

=item start_time()

Return the time when the application started in ticks.

=item current_fps()

Return current number of frames per second, averaged over the last 1000ms.

=item max_fps()

Return maximum number of frames per second we ever achieved.

=item min_fps()

Return minimum number of frames per second we ever achieved.

=item now()

Return current time at the start of the frame in ticks, unwarped. See
L<current_time> for a warped version. This is usefull for tracking the real
time clock as opposed to the warped application clock.

=item current_time()

Return current time at the start of this frame (the same as it is passed
to L<draw_frame()>. This time will be warped by time_warp, e.g a time_warp of
2 makes it go twice as fast as GetTicks(). Note that the returned value will
only change at the start of each frame.

=item lastframe_time()

Return time at the start of the last frame. See current_time(). The same value
is passed to L<draw_frame()>.

=item get_clock

	($day,$hour,$minute,$second,$ms) = $app->get_clock();

Returns the current time (see L<current_time()>) in a day, hour, minute,
second and millisecond format. See L<set_clock()> on how to make the current
time a certain date and time.

=item set_clock

        $app->set_clock($day,$hour,$minute,$second,$ms);

        $app->set_clock(1,12,30);	# set current time to day 1, 12:30

Set's the current time to a specific date and time so that L<get_clock()>
returns the proper format.

=item clock_to_ticks

	$app->clock_to_ticks(0,12,30);		# 12 hours, 30 minutes
	$app->clock_to_ticks(10,5,0,12);	# 10 days, 5 hours, 12 seconds
	$app->clock_to_ticks(0,0,0,123);	# 123 seconds

Return time given as days, hours, minutes, seconds and ms (undef counts as 0).
This is handy for setting timers than expire in a couple of hours, instead of
just a few milli seconds.

=back

=head2 Internal Methods

=over 2

=item _activated_thing()

        $app->_activated_thing($thing);

When a thing (timer, event handler, button etc) is (re)activated, it
notifies the app by calling this routine with itself as argument. Done
automatically by the thing itself.

=item _deactivated_thing()

        $app->_deactivated_thing($thing);

When a thing (timer, event handler, button etc) is deactivated, it
notifies the app by calling this routine with itself as argument. Done
automatically by the thing itself.

=head1 AUTHORS

(c) 2002, 2003, 2004 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<http://irrlicht.sf.net/>

=cut

