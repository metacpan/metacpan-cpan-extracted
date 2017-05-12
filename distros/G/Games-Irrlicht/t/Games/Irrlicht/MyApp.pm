
# sample subclass of Games::Irrlicht

package Games::Irrlicht::MyApp;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Games::Irrlicht;

use vars qw/@ISA/;
@ISA = qw/Games::Irrlicht/;

##############################################################################
# routines that are usually overriden in a subclass

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass. If necc., this might
  # call $self->handle_event().
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;
  
  my $last_print = $self->{myfps}->{last_print} || 0;
  my $now = $self->now();

  # once per second print the achieved FPS
  if ($now - $last_print > 1000)
    {
    print ("# FPS $current_fps/s\n");
    $self->{myfps}->{last_print} = $now;
    }
    
  $self->{myfps}->{drawcounter}++;
 
  # if we have drawn more than 100 frames, add one timer to quit us immiately
  # Note: This is just for testing, normally you just call $self->quit(); :) 
  $self->add_timer ( 0, 1, 0, 0, \&_timer_quit, $self)
    if $self->frames() >= 100;
  }
  
sub _timer_quit
  {
  my ($self, $timer, $timer_id) = @_;

  $self->{myfps}->{timer_fired}++;
  $self->quit();
  }

sub post_init_handler
  {
  my $self = shift;
  $self->{myfps}->{post_init_handler}++;
  $self->{myfps}->{now} = $self->now();	# test that now was initialized
  $self;
  }

sub pre_init_handler
  {
  my $self = shift;
  $self->{myfps}->{pre_init_handler}++;
  $self;
  }

sub quit_handler
  {
  my $self = shift;
  $self->{myfps}->{quit_handler}++;
  $self;
  }

1;

__END__

