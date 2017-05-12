#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# a simple user interface that manipulates window level.
# places in the tcl top window.  Looks for object named viewer
#only use this interface when not doing regression tests

#Set default values 
$sliceNumber = 0 unless defined($sliceNumber);

sub InitializeWindowLevelInterface
  {
   my $l;
   my $res;
   my $w;
   my $zMax;
   my $zMin;
   # Global Variables Declared for this function: viewer, sliceNumber
   # Get parameters from viewer
   $w = $viewer->GetColorWindow;
   $l = $viewer->GetColorLevel;
   $sliceNumber = $viewer->GetZSlice;
   $zMin = $viewer->GetWholeZMin;
   $zMax = $viewer->GetWholeZMax;
   #   set zMin 0
   #   set zMax 128
   $MW->{'.slice'} = $MW->Frame;
   $MW->{'.slice.label'} = $MW->{'.slice'}->Label('-text',"Slice");
   $MW->{'.slice.scale'} = $MW->{'.slice'}->Scale('-from',$zMin,'-to',$zMax,'-variable',\$sliceNumber,'-command',
    sub
     {
      SetSlice($sliceNumber);
     }
   ,'-orient','horizontal');
   #   button .slice.up -text "Up" -command SliceUp
   #   button .slice.down -text "Down" -command SliceDown
   $MW->{'.wl'} = $MW->Frame;
   $MW->{'.wl.f1'} = $MW->{'.wl'}->Frame;
   $MW->{'.wl.f1.windowLabel'} = $MW->{'.wl.f1'}->Label('-text',"Window");
   $MW->{'.wl.f1.window'} = $MW->{'.wl.f1'}->Scale('-from',1,'-to',$w * 2,'-variable',\$window,'-command',
    sub
     {
      SetWindow($window);
     }
   ,'-orient','horizontal');
   $MW->{'.wl.f2'} = $MW->{'.wl'}->Frame;
   $MW->{'.wl.f2.levelLabel'} = $MW->{'.wl.f2'}->Label('-text',"Level");
   $MW->{'.wl.f2.level'} = $MW->{'.wl.f2'}->Scale('-from',$l - $w,'-to',$l + $w,'-variable',\$level,'-command',
    sub
     {
      SetLevel($level);
     }
   ,'-orient','horizontal');

   $MW->{'.wl.video'} = $MW->{'.wl'}->Checkbutton('-text',"Inverse Video",-variable,\$video,'-command',
    sub
     {
      SetInverseVideo($video);
     }
   );

   # resolutions less than 1.0
   if ($w < 10)
    {
     $res = 0.05 * $w;
     $MW->{'.wl.f1.window'}->configure('-resolution',$res,'-from',$res,'-to',2.0 * $w);
     $MW->{'.wl.f2.level'}->configure('-resolution',$res,'-from',0.0 + $l - $w,'-to',0.0 + $l + $w);
    }
   $MW->{'.wl.f1.window'}->set($w);
   $MW->{'.wl.f2.level'}->set($l);
   $MW->{'.ex'} = $MW->Frame;
   $MW->{'.ex.exit'} = $MW->{'.ex'}->Button('-text',"Exit",'-command',\&exit);
   foreach $_ (($MW->{'.slice'},$MW->{'.wl'},$MW->{'.ex'}))
    {
     $_->pack('-side','top');
    }
   foreach $_ (($MW->{'.slice.label'},$MW->{'.slice.scale'}))
    {
     $_->pack('-side','left');
    }
   foreach $_ (($MW->{'.wl.f1'},$MW->{'.wl.f2'},$MW->{'.wl.video'}))
    {
     $_->pack('-side','top');
    }
   foreach $_ (($MW->{'.wl.f1.windowLabel'},$MW->{'.wl.f1.window'}))
    {
     $_->pack('-side','left');
    }
   foreach $_ (($MW->{'.wl.f2.levelLabel'},$MW->{'.wl.f2.level'}))
    {
     $_->pack('-side','left');
    }
   $MW->{'.ex.exit'}->pack('-side','left');
  }
#
sub SetSlice
  {
   my $slice = shift;
   # Global Variables Declared for this function: sliceNumber, viewer
   $viewer->SetZSlice($slice);
   $viewer->Render;
  }
#
sub SetWindow
  {
   my $window = shift;
   # Global Variables Declared for this function: viewer, video
   if ($video)
    {
     $viewer->SetColorWindow(-$window);
    }
   else
    {
     $viewer->SetColorWindow($window);
    }
   $viewer->Render;
  }
#
sub SetLevel
  {
   my $level = shift;
   # Global Variables Declared for this function: viewer
   $viewer->SetColorLevel($level);
   $viewer->Render;
  }
#
sub SetInverseVideo
  {
   my $video = shift;
   # Global Variables Declared for this function: viewer, video, window
   if ($video)
    {
     $viewer->SetColorWindow(-$window);
    }
   else
    {
     $viewer->SetColorWindow($window);
    }
   $viewer->Render;
  }
  
  
InitializeWindowLevelInterface();

Tk->MainLoop;
