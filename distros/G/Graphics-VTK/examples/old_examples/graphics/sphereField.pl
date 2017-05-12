#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This example demonstrates the reading of field data associated with
# dataset point data and cell data.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create pipeline
$reader = Graphics::VTK::PolyDataReader->new;
$reader->SetFileName("$VTK_DATA/sphereField.vtk");
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
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "sphereField.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
