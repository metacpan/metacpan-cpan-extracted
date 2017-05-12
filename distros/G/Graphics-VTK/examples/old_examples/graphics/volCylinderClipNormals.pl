#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Test the recomputation of normals within a subregion
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$reader = Graphics::VTK::SLCReader->new;
$reader->SetFileName("$VTK_DATA/bolt.slc");
$voi = Graphics::VTK::ExtractVOI->new;
$voi->SetInput($reader->GetOutput);
$voi->SetVOI(20,45,20,45,0,30);
$opacityTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction->AddPoint(80,0.0);
$opacityTransferFunction->AddPoint(100,1.0);
$colorTransferFunction = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction->AddRGBPoint(0,1.0,1.0,1.0);
$colorTransferFunction->AddRGBPoint(255,1.0,1.0,1.0);
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty->SetScalarOpacity($opacityTransferFunction);
$volumeProperty->ShadeOn;
$volumeProperty->SetInterpolationTypeToLinear;
$gradest = Graphics::VTK::FiniteDifferenceGradientEstimator->new;
$compositeFunction = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$volumeMapper = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper->SetInput($voi->GetOutput);
$volumeMapper->SetVolumeRayCastFunction($compositeFunction);
$volumeMapper->SetSampleDistance(0.5);
$volumeMapper->SetGradientEstimator($gradest);
$volume = Graphics::VTK::Volume->new;
$volume->SetMapper($volumeMapper);
$volume->SetProperty($volumeProperty);
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetSize(256,256);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddVolume($volume);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->Render;
$ren1->GetActiveCamera->Zoom(1.4);
$gradest->SetSampleSpacingInVoxels(10);
$renWin->Render;
$gradest->CylinderClipOn;
$gradest->SetSampleSpacingInVoxels(1);
$renWin->Render;
$gradest->BoundsClipOn;
$gradest->SetSampleSpacingInVoxels(10);
$gradest->SetBounds(15,25,15,25,0,30);
$renWin->Render;
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
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName("valid/volCylinderClipNormals.ppm");
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
