#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of old spike-face
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a cyberware source
$cyber = Graphics::VTK::PolyDataReader->new;
$cyber->SetFileName("$VTK_DATA/fran_cut.vtk");
$deci = Graphics::VTK::Decimate->new;
$deci->SetInput($cyber->GetOutput);
$deci->SetTargetReduction(0.90);
$deci->SetInitialError(0.0002);
$deci->SetErrorIncrement(0.0002);
$deci->SetMaximumError(0.001);
$deci->SetAspectRatio(20);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($deci->GetOutput);
$normals->SetMaxRecursionDepth(100);
$stripper = Graphics::VTK::Stripper->new;
$stripper->SetInput($normals->GetOutput);
$mask = Graphics::VTK::MaskPolyData->new;
$mask->SetInput($stripper->GetOutput);
$mask->SetOnRatio(2);
$cyberMapper = Graphics::VTK::PolyDataMapper->new;
$cyberMapper->SetInput($mask->GetOutput);
$cyberActor = Graphics::VTK::Actor->new;
$cyberActor->SetMapper($cyberMapper);
$cyberActor->GetProperty->SetColor(1.0,0.49,0.25);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($cyberActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->Azimuth(120);
$sphereProp = $cyberActor->GetProperty;
# do stereo example
$cam1->Zoom(1.4);
$renWin->Render;
#renWin SetFileName "stripF2.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
