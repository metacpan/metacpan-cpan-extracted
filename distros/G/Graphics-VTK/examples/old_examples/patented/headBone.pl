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
$lgt = Graphics::VTK::Light->new;
# create pipeline
$locator = Graphics::VTK::MergePoints->new;
$locator->SetDivisions(64,64,46);
$locator->RetainCellListsOff;
$locator->SetNumberOfPointsPerBucket(2);
$locator->AutomaticOff;
$v16 = Graphics::VTK::Volume16Reader->new;
$v16->SetDataDimensions(128,128);
$v16->GetOutput->SetOrigin(0.0,0.0,0.0);
$v16->SetDataByteOrderToLittleEndian;
$v16->SetFilePrefix("$VTK_DATA/headsq/half");
$v16->SetImageRange(1,93);
$v16->SetDataSpacing(1.6,1.6,1.5);
$iso = Graphics::VTK::MarchingCubes->new;
$iso->SetInput($v16->GetOutput);
$iso->SetValue(0,1150);
$iso->ComputeGradientsOn;
$iso->ComputeScalarsOff;
$iso->SetLocator($locator);
$gradient = Graphics::VTK::VectorNorm->new;
$gradient->SetInput($iso->GetOutput);
$isoMapper = Graphics::VTK::DataSetMapper->new;
$isoMapper->SetInput($gradient->GetOutput);
$isoMapper->ScalarVisibilityOn;
$isoMapper->SetScalarRange(0,1200);
$isoMapper->ImmediateModeRenderingOn;
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoProp = $isoActor->GetProperty;
$isoProp->SetColor(@Graphics::VTK::Colors::antique_white);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($v16->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
#eval $outlineProp SetColor 0 0 0
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$ren1->AddLight($lgt);
$renWin->SetSize(500,500);
$ren1->SetBackground(0.1,0.2,0.4);
$cam1 = $ren1->GetActiveCamera;
$cam1->Elevation(90);
$cam1->SetViewUp(0,0,-1);
$cam1->Zoom(1.3);
$lgt->SetPosition($cam1->GetPosition);
$lgt->SetFocalPoint($cam1->GetFocalPoint);
$ren1->ResetCameraClippingRange;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "headBone.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
