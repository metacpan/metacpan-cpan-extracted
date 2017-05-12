#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# This is an example of how to define your own interaction methods
# in Python or Tcl
# Create the RenderWindow, Renderer and both Actors
$ren = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren);
$style = Graphics::VTK::InteractorStyleUser->new;
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$iren->SetInteractorStyle($style);
# create a plane source and actor
$plane = Graphics::VTK::PlaneSource->new;
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($plane->GetOutput);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
# Add the actors to the renderer, set the background and size
$ren->AddActor($planeActor);
$ren->SetBackground(0.1,0.2,0.4);
# push plane along its normal
#
sub PushPlane
{
 my $oldx;
 my $x;
 $x = ($style->GetLastPos)[0];
 $oldx = ($style->GetOldPos)[0];
 if ($x != $oldx)
  {
   $plane->Push(0.005 * ($x - $oldx));
   $iren->Render;
  }
}
# if user clicked actor, start push interaction
#
sub StartPushPlane
{
 $style->StartUserInteraction;
}
# end push interaction
#
sub EndPushPlane
{
 $style->EndUserInteraction;
}
# set the methods for pushing a plane
$style->SetMiddleButtonPressMethod(
 sub
  {
   StartPushPlane();
  }
);
$style->SetMiddleButtonReleaseMethod(
 sub
  {
   EndPushPlane();
  }
);
$style->SetUserInteractionMethod(
 sub
  {
   PushPlane();
  }
);
# render the image
$iren->Initialize;
$cam1 = $ren->GetActiveCamera;
$cam1->Elevation(-30);
$cam1->Roll(-20);
$renWin->Render;
#renWin SetFileName "CustomInteraction.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
