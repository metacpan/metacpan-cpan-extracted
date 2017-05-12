#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of the Mace example
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create a sphere source and actor
$sphere = Graphics::VTK::SphereSource->new;
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereMapper->GlobalImmediateModeRenderingOn;
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);
$sphereActor2 = Graphics::VTK::Actor->new;
$sphereActor2->SetMapper($sphereMapper);
$sphereActor2->GetProperty->SetRepresentationToWireframe;
$sphereActor2->GetProperty->SetColor(0,0,0);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetWindowName("vtk - Mace");
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Extraction stuff
$planes = Graphics::VTK::Planes->new;
$extract = Graphics::VTK::ExtractPolyDataGeometry->new;
$extract->SetInput($sphere->GetOutput);
$extract->SetImplicitFunction($planes);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($sphereActor);
#ren1 AddActor sphereActor2
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(300,300);
# This zoom is used to perform the clipping
$renWin->Render;
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(4.0);
$planes->SetFrustumPlanes(1.0,$cam1);
$sphereMapper->SetInput($extract->GetOutput);
$renWin->Render;
$cam1->Zoom(0.6);
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName("extractPolyData.tcl.ppm");
#renWin SaveImageAsPPM
#
sub TkCheckAbort
{
 my $foo;
 $foo = $renWin->GetEventPending;
 $renWin->SetAbortRender(1) if ($foo != 0);
}
$renWin->SetAbortCheckMethod(
 sub
  {
   TkCheckAbort();
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
