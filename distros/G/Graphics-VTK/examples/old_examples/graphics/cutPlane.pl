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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a plane 
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetResolution(5,5);
$planeTris = Graphics::VTK::TriangleFilter->new;
$planeTris->SetInput($plane->GetOutput);
$halfPlane = Graphics::VTK::Plane->new;
$halfPlane->SetOrigin('-.13','-.03',0);
$halfPlane->SetNormal(1,'.2',0);
$planeCutter = Graphics::VTK::Cutter->new;
$planeCutter->SetCutFunction($halfPlane);
$planeCutter->SetInput($planeTris->GetOutput);
$planeCutter->SetValue(0,0);
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($planeCutter->GetOutput);
$planeMapper->ScalarVisibilityOff;
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$planeActor->GetProperty->SetDiffuseColor(0,0,0);
$planeActor->GetProperty->SetRepresentationToWireframe;
# Add the actors to the renderer, set the background and size
$ren1->AddActor($planeActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(300,300);
#renWin SetFileName "cutPlane.tcl.ppm"
#renWin SaveImageAsPPM
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
