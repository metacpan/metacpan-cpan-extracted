
# sample subclass of Games::Irrlicht to show the techdemo

package Games::Irrlicht::TechDemo;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Games::Irrlicht;
use File::Spec;

use vars qw/@ISA/;
@ISA = qw/Games::Irrlicht/;

##############################################################################
# routines that are usually overriden in a subclass

sub post_init_handler
  {
  my $self = shift;

  my $fs = $self->getFileSystem();

  # should use Config to get path to media dir
   
  $fs->addZipFileArchive("../media/irrlicht.dat");
  $fs->addZipFileArchive("../media/map-20kdm2.pk3");

  my $device = $self->getIrrlichtDevice();

  my $caption = "Irrlicht Engine Techdemo";
  $device->setWindowCaption($caption);
  }

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
    
  }
  
1;

__END__

