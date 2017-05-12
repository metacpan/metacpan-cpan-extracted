#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# decimate hawaii dataset
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a cyberware source
$reader = Graphics::VTK::PolyDataReader->new;
$reader->SetFileName("$VTK_DATA/honolulu.vtk");
$deci = Graphics::VTK::Decimate->new;
$deci->SetInput($reader->GetOutput);
$deci->SetTargetReduction(0.9);
$deci->SetAspectRatio(20);
$deci->SetInitialError(0.0002);
$deci->SetErrorIncrement(0.0005);
$deci->SetMaximumIterations(6);
$deci->SetInitialFeatureAngle(45);
$hawaiiMapper = Graphics::VTK::PolyDataMapper->new;
$hawaiiMapper->SetInput($deci->GetOutput);
$hawaiiActor = Graphics::VTK::Actor->new;
$hawaiiActor->SetMapper($hawaiiMapper);
$hawaiiActor->GetProperty->SetColor(@Graphics::VTK::Colors::turquoise_blue);
$hawaiiActor->GetProperty->SetRepresentationToWireframe;
# Add the actors to the renderer, set the background and size
$ren1->AddActor($hawaiiActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
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
