#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of the Mace example
# include get the vtk interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$disk = Graphics::VTK::DiskSource->new;
$disk->SetInnerRadius(1.0);
$disk->SetOuterRadius(2.0);
$disk->SetRadialResolution(1);
$disk->SetCircumferentialResolution(20);
$diskMapper = Graphics::VTK::PolyDataMapper->new;
$diskMapper->SetInput($disk->GetOutput);
$diskActor = Graphics::VTK::Actor->new;
$diskActor->SetMapper($diskMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($diskActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(450,450);
# Get handles to some useful objects
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->Render;
#renWin SetFileName Disk.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
