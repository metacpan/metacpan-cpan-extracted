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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# load in the texture map
$imageIn = Graphics::VTK::BMPReader->new;
$imageIn->SetFileName("$VTK_DATA/beach.bmp");
$il = Graphics::VTK::ImageLuminance->new;
$il->SetInput($imageIn->GetOutput);
$ic = Graphics::VTK::ImageCast->new;
$ic->SetOutputScalarTypeToFloat;
$ic->SetInput($il->GetOutput);
# smooth the image
$gs = Graphics::VTK::ImageGaussianSmooth->new;
$gs->SetInput($ic->GetOutput);
$gs->SetDimensionality(2);
$gs->SetRadiusFactors(1,1,0);
# gradient the image
$imgGradient = Graphics::VTK::ImageGradient->new;
$imgGradient->SetInput($gs->GetOutput);
$imgGradient->SetDimensionality(2);
$imgMagnitude = Graphics::VTK::ImageMagnitude->new;
$imgMagnitude->SetInput($imgGradient->GetOutput);
# non maximum suppression
$nonMax = Graphics::VTK::ImageNonMaximumSuppression->new;
$nonMax->SetVectorInput($imgGradient->GetOutput);
$nonMax->SetMagnitudeInput($imgMagnitude->GetOutput);
$nonMax->SetDimensionality(2);
$pad = Graphics::VTK::ImageConstantPad->new;
$pad->SetInput($imgGradient->GetOutput);
$pad->SetOutputNumberOfScalarComponents(3);
$pad->SetConstant(0);
$i2sp1 = Graphics::VTK::ImageToStructuredPoints->new;
$i2sp1->SetInput($nonMax->GetOutput);
$i2sp1->SetVectorInput($pad->GetOutput);
# link edgles
$imgLink = Graphics::VTK::LinkEdgels->new;
$imgLink->SetInput($i2sp1->GetOutput);
$imgLink->SetGradientThreshold(2);
# threshold links
$thresholdEdgels = Graphics::VTK::Threshold->new;
$thresholdEdgels->SetInput($imgLink->GetOutput);
$thresholdEdgels->ThresholdByUpper(10);
$thresholdEdgels->AllScalarsOff;
$gf = Graphics::VTK::GeometryFilter->new;
$gf->SetInput($thresholdEdgels->GetOutput);
$i2sp = Graphics::VTK::ImageToStructuredPoints->new;
$i2sp->SetInput($imgMagnitude->GetOutput);
$i2sp->SetVectorInput($pad->GetOutput);
# subpixel them
$spe = Graphics::VTK::SubPixelPositionEdgels->new;
$spe->SetInput($gf->GetOutput);
$spe->SetGradMaps($i2sp->GetOutput);
$strip = Graphics::VTK::Stripper->new;
$strip->SetInput($spe->GetOutput);
$dsm = Graphics::VTK::PolyDataMapper->new;
$dsm->SetInput($strip->GetOutput);
$dsm->SetScalarRange(0,70);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($dsm);
$planeActor->GetProperty->SetAmbient('.5');
$planeActor->GetProperty->SetDiffuse(1.0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($planeActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);
# render the image
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$ren1->GetActiveCamera->Zoom(1.4);
$renWin->Render;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
