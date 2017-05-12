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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$atext = Graphics::VTK::VectorText->new;
$count = 3;
$atext->SetText("Welcome to VTK
An exciting new adventure 
brought to you by over 
$count monkeys at work for 
over three years.");
$shrink = Graphics::VTK::ShrinkPolyData->new;
$shrink->SetInput($atext->GetOutput);
$shrink->SetShrinkFactor(0.1);
$spikeMapper = Graphics::VTK::PolyDataMapper->new;
$spikeMapper->SetInput($shrink->GetOutput);
$spikeActor = Graphics::VTK::Actor->new;
$spikeActor->SetMapper($spikeMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($spikeActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,300);
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(2.4);
for ((); $count < 27; ())
 {
  $renWin->Render;
  $count = $count + 1;
  $shrink->SetShrinkFactor($count / 27.0);
  $atext->SetText("Welcome to VTK
An exciting new adventure 
brought to you by over 
$count monkeys at work for 
over three years.");
 }
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "vectext.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
