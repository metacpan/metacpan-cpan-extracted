#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

eval
 {
  $load->vtktcl;
 }
;
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
$grabber = Graphics::VTK::VideoSource->new;
#grabber SetOutputFormatToRGB  
#grabber SetFrameSize 640 480 1 
#grabber SetOutputWholeExtent 0 319 0 239 0 0 
$grabber->SetFrameBufferSize(50);
$grabber->SetNumberOfOutputFrames(50);
$grabber->Grab;
$grabber->GetOutput->UpdateInformation;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($grabber->GetOutput);
#[viewer GetImageWindow] DoubleBufferOn  
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
$viewer->SetZSlice(0);
$viewer->Render;
#
sub animate
{
 my $after;
 # Global Variables Declared for this function: grabber, viewer
 if ($grabber->GetPlaying == 1)
  {
   $viewer->Render;
   $after->1('animate');
  }
}
#
sub Play
{
 my $animate;
 # Global Variables Declared for this function: grabber
 if ($grabber->GetPlaying != 1)
  {
   $grabber->Play;
   animate();
  }
}
#
sub Stop
{
 # Global Variables Declared for this function: grabber
 $grabber->Stop;
}
#
sub Grab
{
 # Global Variables Declared for this function: grabber, viewer
 $grabber->Grab;
 $viewer->Render;
}
$MW->{'.controls'} = $MW->Frame;
$MW->{'.controls.grab'} = $MW->{'.controls'}->Button('-text',"Grab",'-command',
 sub
  {
   Grab();
  }
);
$MW->{'.controls.grab'}->pack('-side','left');
$MW->{'.controls.stop'} = $MW->{'.controls'}->Button('-text',"Stop",'-command',
 sub
  {
   Stop();
  }
);
$MW->{'.controls.stop'}->pack('-side','left');
$MW->{'.controls.play'} = $MW->{'.controls'}->Button('-text',"Play",'-command',
 sub
  {
   Play();
  }
);
$MW->{'.controls.play'}->pack('-side','left');
$MW->{'.controls'}->pack('-side','top');
#
sub SetFrameRate
{
 my $r = shift;
 # Global Variables Declared for this function: grabber
 $grabber->SetFrameRate($r);
}
$MW->{'.rate'} = $MW->Frame;
$MW->{'.rate.label'} = $MW->{'.rate'}->Label('-text',"Frames/s");
$MW->{'.rate.scale'} = $MW->{'.rate'}->Scale('-from',0.0,'-to',60.0,'-command',
 sub
  {
   SetFrameRate();
  }
,'-orient','horizontal');
$MW->{'.rate.scale'}->set($grabber->GetFrameRate);
$MW->{'.rate.label'}->pack('-side','left');
$MW->{'.rate.scale'}->pack('-side','left');
$MW->{'.rate'}->pack('-side','top');
#
sub SetFrame
{
 my $f = shift;
 # Global Variables Declared for this function: viewer
 $viewer->SetZSlice($f);
 $viewer->Render;
}
$MW->{'.viewframe'} = $MW->Frame;
$MW->{'.viewframe.label'} = $MW->{'.viewframe'}->Label('-text',"Frame #");
$MW->{'.viewframe.scale'} = $MW->{'.viewframe'}->Scale('-from',0,'-to',49,'-command',
 sub
  {
   SetFrame();
  }
,'-orient','horizontal');
$MW->{'.viewframe.label'}->pack('-side','left');
$MW->{'.viewframe.scale'}->pack('-side','left');
$MW->{'.viewframe'}->pack('-side','top');
$MW->{'.ex'} = $MW->Frame;
$MW->{'.ex.button'} = $MW->{'.ex'}->Button('-text',"Exit",'-command',
 sub
  {
   exit();
  }
);
$MW->{'.ex.button'}->pack('-side','left');
$MW->{'.ex'}->pack('-side','top');

Tk->MainLoop;
