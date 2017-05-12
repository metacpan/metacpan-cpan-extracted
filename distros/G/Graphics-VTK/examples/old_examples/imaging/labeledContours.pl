#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# demonstrate labeling of contour with scalar value
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Read a slice and contour it
$v16 = Graphics::VTK::Volume16Reader->new;
$v16->SetDataDimensions(128,128);
$v16->GetOutput->SetOrigin(0.0,0.0,0.0);
$v16->SetDataByteOrderToLittleEndian;
$v16->SetFilePrefix("$VTK_DATA/headsq/half");
$v16->SetImageRange(45,45);
$v16->SetDataSpacing(1.6,1.6,1.5);
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($v16->GetOutput);
$iso->GenerateValues(6,500,1150);
$iso->Update;
$numPts = $iso->GetOutput->GetNumberOfPoints;
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($iso->GetOutput);
$isoMapper->ScalarVisibilityOn;
$isoMapper->SetScalarRange($iso->GetOutput->GetScalarRange);
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
# Subsample the points and label them
$mask = Graphics::VTK::MaskPoints->new;
$mask->SetInput($iso->GetOutput);
$mask->SetOnRatio($numPts / 50);
$mask->SetMaximumNumberOfPoints(50);
$mask->RandomModeOn;
# Create labels for points - only show visible points
$visPts = Graphics::VTK::SelectVisiblePoints->new;
$visPts->SetInput($mask->GetOutput);
$visPts->SetRenderer($ren1);
$ldm = Graphics::VTK::LabeledDataMapper->new;
$ldm->SetInput($mask->GetOutput);
#    ldm SetInput [visPts GetOutput];#uncomment if visibility calculation is necessary
$ldm->SetLabelFormat("%g");
$ldm->SetLabelModeToLabelScalars;
$ldm->SetFontFamilyToArial;
$ldm->SetFontSize(8);
$contourLabels = Graphics::VTK::Actor2D->new;
$contourLabels->SetMapper($ldm);
$contourLabels->SetMapper($ldm);
$contourLabels->GetProperty->SetColor(1,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor2D($isoActor);
$ren1->AddActor2D($contourLabels);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(300,300);
$renWin->Render;
$ren1->GetActiveCamera->Zoom(1.5);
#renWin SetFileName "labeledContours.tcl.ppm"
#renWin SaveImageAsPPM
# render the image
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
