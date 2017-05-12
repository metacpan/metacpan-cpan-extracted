#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

## This is a grid of MIP volumes - with 3 values permuted - the
## type of maximization (scalar value or opacity) the type of
## color (grey or RGB) and the interpolation type (nearest or linear)
$MW->withdraw;
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
#
sub TkCheckAbort
{
 my $foo;
 $foo = $renWin->GetEventPending;
 $renWin->SetAbortRender(1) if ($foo != 0);
}
$renWin->SetAbortCheckMethod(
 sub
  {
   TkCheckAbort();
  }
);
$reader = Graphics::VTK::SLCReader->new;
$reader->SetFileName("$VTK_DATA/sphere.slc");
$opacityTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction->AddPoint(0,0.0);
$opacityTransferFunction->AddPoint(57,0.0);
$opacityTransferFunction->AddPoint(64,0.3);
$opacityTransferFunction->AddPoint(71,0.0);
$opacityTransferFunction->AddPoint(117,0.0);
$opacityTransferFunction->AddPoint(124,0.4);
$opacityTransferFunction->AddPoint(131,0.0);
$opacityTransferFunction->AddPoint(180,0.0);
$opacityTransferFunction->AddPoint(192,0.6);
$opacityTransferFunction->AddPoint(210,0.0);
$colorTransferFunction = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction->AddRGBPoint(0,0.0,0.0,1.0);
$colorTransferFunction->AddRGBPoint(90,0.0,0.0,1.0);
$colorTransferFunction->AddRGBPoint(91,0.0,1.0,0.0);
$colorTransferFunction->AddRGBPoint(160,0.0,1.0,0.0);
$colorTransferFunction->AddRGBPoint(161,1.0,0.0,0.0);
$colorTransferFunction->AddRGBPoint(255,1.0,0.0,0.0);
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetScalarOpacity($opacityTransferFunction);
$volumeProperty->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty->SetInterpolationTypeToLinear;
$volumeProperty->ShadeOn;
$volumeProperty->SetDiffuse(0.8);
$volumeProperty->SetSpecular(0.4);
$volumeProperty->SetSpecularPower(80);
$CompositeFunction1 = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$CompositeFunction2 = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$CompositeFunction1->SetCompositeMethod(
 sub
  {
   ToInterpolateFirst();
  }
);
$CompositeFunction2->SetCompositeMethod(
 sub
  {
   ToClassifyFirst();
  }
);
$GradientEstimator = Graphics::VTK::FiniteDifferenceGradientEstimator->new;
$volumeMapper1 = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper1->SetInput($reader->GetOutput);
$volumeMapper1->SetVolumeRayCastFunction($CompositeFunction1);
$volumeMapper1->SetGradientEstimator($GradientEstimator);
$volumeMapper1->SetSampleDistance(0.2);
$volumeMapper1->SetCroppingRegionPlanes(0,49,20,49,0,49);
$volumeMapper1->CroppingOn;
$volumeMapper2 = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper2->SetInput($reader->GetOutput);
$volumeMapper2->SetVolumeRayCastFunction($CompositeFunction2);
$volumeMapper2->SetGradientEstimator($GradientEstimator);
$volumeMapper2->SetSampleDistance(0.2);
$volumeMapper2->SetCroppingRegionPlanes(0,49,20,49,0,49);
$volumeMapper2->CroppingOn;
$volume1 = Graphics::VTK::Volume->new;
$volume1->SetMapper($volumeMapper1);
$volume1->SetProperty($volumeProperty);
$ren1->AddVolume($volume1);
$volume2 = Graphics::VTK::Volume->new;
$volume2->SetMapper($volumeMapper2);
$volume2->SetProperty($volumeProperty);
$ren1->AddVolume($volume2);
$volume2->AddPosition(48,0,0);
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetRadius(10);
$sphere->SetCenter(24.5,24.5,24.5);
$sphere->SetThetaResolution(20);
$sphere->SetPhiResolution(20);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($sphere->GetOutput);
$actor1 = Graphics::VTK::Actor->new;
$actor1->SetMapper($mapper);
$actor1->GetProperty->SetColor('.8',0,1);
$actor1->GetProperty->SetDiffuse(0.7);
$actor1->GetProperty->SetSpecular(0.3);
$actor1->GetProperty->SetSpecularPower(80);
$actor2 = Graphics::VTK::Actor->new;
$actor2->SetMapper($mapper);
$actor2->GetProperty->SetColor('.8',0,1);
$actor2->GetProperty->SetDiffuse(0.7);
$actor2->GetProperty->SetSpecular(0.3);
$actor2->GetProperty->SetSpecularPower(80);
$actor2->AddPosition(48,0,0);
$ren1->AddActor($actor1);
$ren1->AddActor($actor2);
$renWin->SetSize(400,200);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->ParallelProjectionOn;
$ren1->GetActiveCamera->SetParallelScale(500);
$ren1->GetActiveCamera->Elevation(-30);
$renWin->Render;
$light = Graphics::VTK::Light->new;
$light->SetPosition(-1,1,1);
$light->SetFocalPoint(0,0,0);
$light->SwitchOn;
$light->SetIntensity(0.7);
$ren1->AddLight($light);
$light2 = Graphics::VTK::Light->new;
$light2->SetPosition(1,1,1);
$light2->SetFocalPoint(0,0,0);
$light2->SwitchOn;
$light2->SetIntensity(0.7);
$ren1->AddLight($light2);
$ren1->GetActiveCamera->SetParallelScale(24);
$renWin->Render;
#renWin SetFileName "valid/volCompareCompositeMethods.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
