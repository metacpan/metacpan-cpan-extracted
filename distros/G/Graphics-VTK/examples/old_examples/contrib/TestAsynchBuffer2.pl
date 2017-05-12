#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example provides interactive isosurface value selection
# using a low res data set.  The high res version is computed
# when the mouse is released.  The computation of the high res
# surface can be interrupted with another mouse selection.  
# It uses an asynch buffer so the interaction continues 
# while the high res surface is being computed.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$lgt = Graphics::VTK::Light->new;
# create pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$reader->SetDataSpacing(1.6,1.6,3.0);
$reader->Update;
$shrink = Graphics::VTK::ImageShrink3D->new;
$shrink->SetInput($reader->GetOutput);
$shrink->SetShrinkFactors(4,4,4);
$shrink->AveragingOff;
$shrink->Update;
$IsoValue = 1150;
$iso = Graphics::VTK::ImageMarchingCubes->new;
$iso->SetInput($shrink->GetOutput);
$iso->SetValue(0,$IsoValue);
$iso->ComputeGradientsOn;
$iso->ComputeScalarsOff;
$buf = Graphics::VTK::AsynchronousBuffer->new;
$buf->SetInput($iso->GetOutput);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($buf->GetOutput);
$isoMapper->ScalarVisibilityOff;
$isoMapper->ImmediateModeRenderingOn;
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoProp = $isoActor->GetProperty;
$isoProp->SetColor(@Graphics::VTK::Colors::antique_white);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
#eval $outlineProp SetColor 0 0 0
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$ren1->AddLight($lgt);
$renWin->SetSize(500,500);
$ren1->SetBackground(0.1,0.2,0.4);
$cam1 = $ren1->GetActiveCamera;
$cam1->Elevation(90);
$cam1->SetViewUp(0,0,-1);
$cam1->Zoom(1.3);
$lgt->SetPosition($cam1->GetPosition);
$lgt->SetFocalPoint($cam1->GetFocalPoint);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# low res quick render
$renWin->Render;
# start an asynchronous high res render
$buf->BlockingOff;
$iso->SetInput($reader->GetOutput);
$renWin->Render;
$iren->Initialize;
#renWin SetFileName "headBone.tcl.ppm"
#renWin SaveImageAsPPM
# ----- Set up the slider, and interactive choice stuff. -----
# call back of the slider
#
sub SetSurfaceValue
{
 my $val = shift;
 my $return;
 # This check may not be needed, but it makes things cleaner.
 return if ($buf->GetFinished == 0);
 $iso->SetValue(0,$val);
}
# Called when mouse is first pressed over the slider.
#
sub StartInteraction
{
 #LogMessage "start interaction"
 if ($buf->GetFinished == 0)
  {
   # abort the iso surface execution
   $iso->AbortExecuteOn;
   # wait until the other thread finishes
   while ($buf->GetFinished == 0)
    {
     #LogMessage "waiting for iso to abort"
     # sleep 1
    }
  }
 $iso->SetInput($shrink->GetOutput);
 $buf->BlockingOn;
}
# Called when mouse is released.  
# Starts the generatikon of the full res model.
#
sub StopInteraction
{
 #LogMessage "start interaction"
 $iso->SetInput($reader->GetOutput);
 $buf->BlockingOff;
}
$QUIT_FLAG = 0;
#
sub Quit
{
 # Global Variables Declared for this function: QUIT_FLAG
 # signal loop to exit
 $QUIT_FLAG = 1;
}
# create a slider to set the iso surface value.
$MW->{'.ui'} = $MW->Toplevel;
$MW->{'.ui.scale'} = $MW->{'.ui'}->Scale('-from',0,'-to',3000,'-variable',\$IsoValue,'-command',
 sub
  {
   SetSurfaceValue();
  }
,'-orient','horizontal');
$MW->{'.ui.quit'} = $MW->{'.ui'}->Button('-text',"Quit",'-command',
 sub
  {
   Quit();
  }
);
$MW->{'.ui.scale'}->pack('-side','top','-expand','t','-fill','both');
$MW->{'.ui.quit'}->pack('-side','top','-expand','t','-fill','both');
# extra calls to change modes (interactive, full res)
$MW->{'.ui.scale'}->bind('<ButtonPress-1>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   StartInteraction();
  }
);
$MW->{'.ui.scale'}->bind('<ButtonRelease-1>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   StopInteraction();
  }
);
$MW->withdraw;
# we need our own little event loop to detect when our input has been changed
# by another thread
$RENDER_TIME = 0;
while (1)
 {
  # Global Variables Declared for this function: QUIT_FLAG
  # tcl handle events
  #LogMessage "update"
  $MW->update;
  exit() if ($QUIT_FLAG);
  # check if anything has changed.
  $buf->UpdateInformation;
  $DATA_TIME = $buf->GetOutput->GetPipelineMTime;
  if ($DATA_TIME > $RENDER_TIME)
   {
    $renWin->Render;
    $RENDER_TIME = $DATA_TIME;
   }
  else
   {
    $after->10;
   }
 }
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
