#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This example demonstrates the reading of point data and cell data
# simultaneously.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create pipeline
$reader = Graphics::VTK::PolyDataReader->new;
$reader->SetFileName("$VTK_DATA/polyEx.vtk");
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($reader->GetOutput);
$mapper->SetScalarRange($reader->GetOutput->GetScalarRange);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($actor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange('.348',17.43);
$cam1->SetPosition(2.92,2.62,-0.836);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.436,-0.067,-0.897);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "polyEx.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
