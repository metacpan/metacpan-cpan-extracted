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
# read a vtk file
$stla = Graphics::VTK::STLReader->new;
$stla->SetFileName("$VTK_DATA/Viewpoint/cow.stl");
$stla->MergingOff;
$stlaMapper = Graphics::VTK::PolyDataMapper->new;
$stlaMapper->SetInput($stla->GetOutput);
$stlaActor = Graphics::VTK::Actor->new;
$stlaActor->SetMapper($stlaMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($stlaActor);
$ren1->SetBackground(0.2,0.3,0.4);
$renWin->SetSize(256,256);
$ren1->GetActiveCamera->SetPosition(8.53462,-15.3133,7.36157);
$ren1->GetActiveCamera->SetFocalPoint(1.14624,0.166092,-0.45963);
$ren1->GetActiveCamera->SetViewAngle(30);
$ren1->GetActiveCamera->SetViewUp(-0.10844,0.406593,0.907151);
$ren1->GetActiveCamera->SetViewPlaneNormal(0.39193,-0.821132,0.414889);
$ren1->GetActiveCamera->SetClippingRange(2,200);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "asciiSTL.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
