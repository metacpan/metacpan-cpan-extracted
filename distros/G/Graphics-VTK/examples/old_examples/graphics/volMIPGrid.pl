#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

## This is a grid of MIP volumes - with 3 values permuted - the
## type of maximization (scalar value or opacity) the type of
## color (grey or RGB) and the interpolation type (nearest or linear)
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
$reader->SetFileName("$VTK_DATA/poship.slc");
$opacityTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction->AddPoint(0,0.0);
$opacityTransferFunction->AddPoint(128,1.0);
$opacityTransferFunction->AddPoint(255,0.0);
$colorTransferFunction = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction->AddRGBPoint(0,1.0,0.0,0.0);
$colorTransferFunction->AddRGBPoint(31,1.0,0.5,0.0);
$colorTransferFunction->AddRGBPoint(63,1.0,1.0,0.3);
$colorTransferFunction->AddRGBPoint(95,0.0,1.0,0.0);
$colorTransferFunction->AddRGBPoint(127,0.3,0.7,0.5);
$colorTransferFunction->AddRGBPoint(159,0.0,0.0,1.0);
$colorTransferFunction->AddRGBPoint(191,1.0,0.0,1.0);
$colorTransferFunction->AddRGBPoint(223,1.0,0.5,1.0);
$colorTransferFunction->AddRGBPoint(255,1.0,1.0,1.0);
$greyTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$greyTransferFunction->AddPoint(0,1.0);
$greyTransferFunction->AddPoint(255,1.0);
$volumeProperty1 = Graphics::VTK::VolumeProperty->new;
$volumeProperty2 = Graphics::VTK::VolumeProperty->new;
$volumeProperty3 = Graphics::VTK::VolumeProperty->new;
$volumeProperty4 = Graphics::VTK::VolumeProperty->new;
$volumeProperty1->SetScalarOpacity($opacityTransferFunction);
$volumeProperty2->SetScalarOpacity($opacityTransferFunction);
$volumeProperty3->SetScalarOpacity($opacityTransferFunction);
$volumeProperty4->SetScalarOpacity($opacityTransferFunction);
$volumeProperty1->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty2->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty3->SetColor(@Graphics::VTK::Colors::greyTransferFunction);
$volumeProperty4->SetColor(@Graphics::VTK::Colors::greyTransferFunction);
$volumeProperty1->SetInterpolationTypeToNearest;
$volumeProperty2->SetInterpolationTypeToLinear;
$volumeProperty3->SetInterpolationTypeToNearest;
$volumeProperty4->SetInterpolationTypeToLinear;
$MIPFunction1 = Graphics::VTK::VolumeRayCastMIPFunction->new;
$MIPFunction2 = Graphics::VTK::VolumeRayCastMIPFunction->new;
$MIPFunction1->SetMaximizeMethod(
 sub
  {
   ToScalarValue();
  }
);
$MIPFunction2->SetMaximizeMethod(
 sub
  {
   ToOpacity();
  }
);
$volumeMapper1 = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper2 = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper1->SetInput($reader->GetOutput);
$volumeMapper1->SetVolumeRayCastFunction($MIPFunction1);
$volumeMapper2->SetInput($reader->GetOutput);
$volumeMapper2->SetVolumeRayCastFunction($MIPFunction2);
for ($i = 1; $i <= 8; $i += 1)
 {
  $volume = Graphics::VTK::Volume->new($,'i');
  $j = int(($i - 1) / 4);
  $yoff = 70 * $j;
  $j += 1;
  $volume->_('i','SetMapper',"volumeMapper$",'j');
  $j = (($i - 1) % 4);
  $xoff = 70 * $j;
  $j += 1;
  $volume->_('i','SetProperty',"volumeProperty$",'j');
  $ren1->AddVolume("volume$",'i');
  $volume->_('i','AddPosition',$xoff,$yoff,0);
 }
$renWin->SetSize(600,300);
$ren1->GetActiveCamera->ParallelProjectionOn;
$ren1->GetActiveCamera->SetParallelScale(70);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "valid/volMIPGrid.tcl.ppm"
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
