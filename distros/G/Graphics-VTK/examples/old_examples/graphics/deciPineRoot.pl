#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui and colors
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$reader = Graphics::VTK::MCubesReader->new;
$reader->SetFileName("$VTK_DATA/pineRoot/pine_root.tri");
$reader->FlipNormalsOff;
$deci = Graphics::VTK::Decimate->new;
$deci->SetInput($reader->GetOutput);
$deci->SetTargetReduction(0.9);
$deci->SetAspectRatio(20);
$deci->SetInitialError(0.0005);
$deci->SetErrorIncrement(0.001);
$deci->SetMaximumIterations(6);
$deci->SetInitialFeatureAngle(30);
$connect = Graphics::VTK::ConnectivityFilter->new;
$connect->SetInput($deci->GetOutput);
$connect->SetExtractionModeToLargestRegion;
$isoMapper = Graphics::VTK::DataSetMapper->new;
$isoMapper->SetInput($connect->GetOutput);
$isoMapper->ScalarVisibilityOff;
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoActor->GetProperty->SetColor(@Graphics::VTK::Colors::raw_sienna);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(750,750);
$ren1->SetBackground($slate_grey);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam = $ren1->GetActiveCamera;
$cam->SetFocalPoint(40.6018,37.2813,50.1953);
$cam->SetPosition(40.6018,-280.533,47.0172);
$cam->ComputeViewPlaneNormal;
$cam->SetClippingRange(26.1073,1305.36);
$cam->SetViewAngle(20.9219);
$cam->SetViewUp(0.0,0.0,1.0);
$renWin->Render;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
$iren->Start;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
