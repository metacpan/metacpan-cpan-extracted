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
# create pipeline
$reader = Graphics::VTK::StructuredPointsReader->new;
$reader->SetFileName("$VTK_DATA/carotid.vtk");
$hhog = Graphics::VTK::HedgeHog->new;
$hhog->SetInput($reader->GetOutput);
$hhog->SetScaleFactor(0.3);
$lut = Graphics::VTK::LookupTable->new;
#    lut SetHueRange .667 0.0
$lut->Build;
$hhogMapper = Graphics::VTK::PolyDataMapper->new;
$hhogMapper->SetInput($hhog->GetOutput);
$hhogMapper->SetScalarRange(50,550);
$hhogMapper->SetLookupTable($lut);
$hhogMapper->ImmediateModeRenderingOn;
$hhogActor = Graphics::VTK::Actor->new;
$hhogActor->SetMapper($hhogMapper);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
#eval $outlineProp SetColor 0 0 0
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($hhogActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
#renWin SetSize 1000 1000
$ren1->SetBackground(0.1,0.2,0.4);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(1.5);
$renWin->Render;
#renWin SetFileName "complexV.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
