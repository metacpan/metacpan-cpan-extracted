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
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create lines
$reader = Graphics::VTK::PolyDataReader->new;
$reader->SetFileName("$VTK_DATA/hello.vtk");
$lineMapper = Graphics::VTK::PolyDataMapper->new;
$lineMapper->SetInput($reader->GetOutput);
$lineActor = Graphics::VTK::Actor->new;
$lineActor->SetMapper($lineMapper);
$lineActor->GetProperty->SetColor(@Graphics::VTK::Colors::red);
# create implicit model
$imp = Graphics::VTK::ImplicitModeller->new;
$imp->SetInput($reader->GetOutput);
$imp->SetSampleDimensions(110,40,20);
$imp->SetMaximumDistance(0.25);
$imp->SetModelBounds(-1.0,10.0,-1.0,3.0,-1.0,1.0);
$contour = Graphics::VTK::ContourFilter->new;
$contour->SetInput($imp->GetOutput);
$contour->SetValue(0,0.25);
$impMapper = Graphics::VTK::PolyDataMapper->new;
$impMapper->SetInput($contour->GetOutput);
$impMapper->ScalarVisibilityOff;
$impActor = Graphics::VTK::Actor->new;
$impActor->SetMapper($impMapper);
$impActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$impActor->GetProperty->SetOpacity(0.5);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($lineActor);
$ren1->AddActor($impActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(600,250);
$camera = Graphics::VTK::Camera->new;
$camera->SetClippingRange(1.81325,90.6627);
$camera->SetFocalPoint(4.5,1,0);
$camera->SetPosition(4.5,1.0,6.73257);
$camera->ComputeViewPlaneNormal;
$camera->SetViewUp(0,1,0);
$camera->Zoom(0.8);
$ren1->SetActiveCamera($camera);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "hello.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
