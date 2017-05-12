#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version showing diffs between flat & gouraud
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a sphere source and actor
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetThetaResolution(30);
$sphere->SetPhiResolution(30);
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereActor = Graphics::VTK::LODActor->new;
$sphereActor->SetMapper($sphereMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($sphereActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(375,375);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.4);
$iren->Initialize;
$renWin->Render;
$cam1->Azimuth(30);
$cam1->Elevation(-50);
$prop = $sphereActor->GetProperty;
$prop->SetDiffuseColor(1.0,0,0);
$prop->SetDiffuse(0.6);
$prop->SetSpecularPower(5);
$prop->SetSpecular(0.5);
$renWin->Render;
$renWin->SetFileName('f1.ppm');
#renWin SaveImageAsPPM
$prop->SetSpecular(1.0);
$renWin->Render;
#renWin SetFileName specular.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
