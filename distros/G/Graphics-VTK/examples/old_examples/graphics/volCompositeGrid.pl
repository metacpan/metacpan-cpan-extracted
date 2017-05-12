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
$opacityTransferFunction->AddPoint(20,0.0);
$opacityTransferFunction->AddPoint(120,0.25);
$gradopTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$gradopTransferFunction->AddPoint(0,0.0);
$gradopTransferFunction->AddPoint(5,0.0);
$gradopTransferFunction->AddPoint(10,1.0);
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
$volumeProperty5 = Graphics::VTK::VolumeProperty->new;
$volumeProperty6 = Graphics::VTK::VolumeProperty->new;
$volumeProperty7 = Graphics::VTK::VolumeProperty->new;
$volumeProperty8 = Graphics::VTK::VolumeProperty->new;
$volumeProperty9 = Graphics::VTK::VolumeProperty->new;
$volumeProperty10 = Graphics::VTK::VolumeProperty->new;
$volumeProperty11 = Graphics::VTK::VolumeProperty->new;
$volumeProperty12 = Graphics::VTK::VolumeProperty->new;
$volumeProperty13 = Graphics::VTK::VolumeProperty->new;
$volumeProperty14 = Graphics::VTK::VolumeProperty->new;
$volumeProperty15 = Graphics::VTK::VolumeProperty->new;
$volumeProperty16 = Graphics::VTK::VolumeProperty->new;
for ($i = 0; $i < 16; $i += 1)
 {
  $p = $i + 1;
  $w = (($i % 2) / 1);
  $x = (($i % 4) / 2);
  $y = (($i % 8) / 4);
  $z = (($i % 16) / 8);
  $volumeProperty->_('p','SetScalarOpacity',$opacityTransferFunction);
  if ($w)
   {
    $volumeProperty->_('p','SetColor',$colorTransferFunction);
   }
  else
   {
    $volumeProperty->_('p','SetColor',$greyTransferFunction);
   }
  if ($x)
   {
    $volumeProperty->_('p','SetInterpolationTypeToLinear');
   }
  else
   {
    $volumeProperty->_('p','SetInterpolationTypeToNearest');
   }
  if ($y)
   {
    $volumeProperty->_('p','ShadeOn');
   }
  else
   {
    $volumeProperty->_('p','ShadeOff');
   }
  $volumeProperty->_('p','SetGradientOpacity',$gradopTransferFunction) if ($z);
 }
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
$volumeMapper1->SetSampleDistance(0.3);
$volumeMapper2 = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper2->SetInput($reader->GetOutput);
$volumeMapper2->SetVolumeRayCastFunction($CompositeFunction2);
$volumeMapper2->SetGradientEstimator($GradientEstimator);
for ($j = 1; $j <= 2; $j += 1)
 {
  for ($i = 1; $i <= 16; $i += 1)
   {
    $volume_{$i} = Graphics::VTK::Volume->new($,'j');
    $volume_{$i}->_('j','SetMapper',"volumeMapper$",'j');
    $volume_{$i}->_('j','SetProperty',"volumeProperty$",'i');
    $k = int(($i - 1) / 8) + 2 * ($j - 1);
    $yoff = 70 * $k;
    $k = (($i - 1) % 8);
    $xoff = 70 * $k;
    $ren1->AddVolume($volume_{$i},$,'j');
    $volume_{$i}->_('j','AddPosition',$xoff,$yoff,0);
   }
 }
$renWin->SetSize(600,300);
$ren1->GetActiveCamera->ParallelProjectionOn;
$ren1->GetActiveCamera->SetParallelScale(140);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "valid/volCompositeGrid.tcl.ppm"
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
