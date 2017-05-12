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
# and some nice colors
use Graphics::VTK::Colors;
# Now create the RenderWindow, Renderer and Interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$imageIn = Graphics::VTK::PNMReader->new;
$imageIn->SetFileName("$VTK_DATA/B.pgm");
$gaussian = Graphics::VTK::ImageGaussianSmooth->new;
$gaussian->SetStandardDeviations(2,2);
$gaussian->SetDimensionality(2);
$gaussian->SetRadiusFactors(1,1);
$gaussian->SetInput($imageIn->GetOutput);
$toStructuredPoints = Graphics::VTK::ImageToStructuredPoints->new;
$toStructuredPoints->SetInput($gaussian->GetOutput);
$geometry = Graphics::VTK::StructuredPointsGeometryFilter->new;
$geometry->SetInput($toStructuredPoints->GetOutput);
$aClipper = Graphics::VTK::ClipPolyData->new;
$aClipper->SetInput($geometry->GetOutput);
$aClipper->SetValue(127.5);
$aClipper->GenerateClipScalarsOff;
$aClipper->InsideOutOn;
$aClipper->GetOutput->GetPointData->CopyScalarsOff;
$aClipper->Update;
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($aClipper->GetOutput);
$mapper->ScalarVisibilityOff;
$letter = Graphics::VTK::Actor->new;
$letter->SetMapper($mapper);
$ren1->AddActor($letter);
$letter->GetProperty->SetDiffuseColor(0,0,0);
$letter->GetProperty->SetRepresentationToWireframe;
$ren1->SetBackground(1,1,1);
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(320,320);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# render the image
$renWin->Render;
#renWin SetFileName "createBFont.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
