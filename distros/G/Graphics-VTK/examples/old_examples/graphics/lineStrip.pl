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
# create pipeline
$v16 = Graphics::VTK::Volume16Reader->new;
$v16->SetDataDimensions(128,128);
$v16->GetOutput->SetOrigin(0.0,0.0,0.0);
$v16->SetDataByteOrderToLittleEndian;
$v16->SetFilePrefix("$VTK_DATA/headsq/half");
$v16->SetImageRange(45,45);
$v16->SetDataSpacing(1.6,1.6,1.5);
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($v16->GetOutput);
$iso->GenerateValues(6,600,1200);
$stripper = Graphics::VTK::Stripper->new;
$stripper->SetInput($iso->GetOutput);
$tuber = Graphics::VTK::TubeFilter->new;
$tuber->SetInput($stripper->GetOutput);
$tuber->SetNumberOfSides(4);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($tuber->GetOutput);
$isoMapper->SetScalarRange(600,1200);
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($v16->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
#eval $outlineProp SetColor 0 0 0
# The graphics stuff
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(400,400);
$ren1->GetActiveCamera->Zoom(1.4);
$ren1->SetBackground(0.1,0.2,0.4);
$iren->Initialize;
#renWin SetFileName "valid/lineStrip.tcl.ppm"
#renWin SaveImageAsPPM
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
