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
# Simple volume rendering example.
$reader = Graphics::VTK::SLCReader->new;
$reader->SetFileName("$VTK_DATA/sphere.slc");
# Create transfer functions for opacity and color
$opacityTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction->AddPoint(10,0.0);
$opacityTransferFunction->AddPoint(255,0.5);
$colorTransferFunction = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction->AddRGBPoint(0.0,0.0,0.0,0.0);
$colorTransferFunction->AddRGBPoint(64.0,1.0,0.0,0.0);
$colorTransferFunction->AddRGBPoint(128.0,0.0,0.0,1.0);
$colorTransferFunction->AddRGBPoint(192.0,0.0,1.0,0.0);
$colorTransferFunction->AddRGBPoint(255.0,0.0,0.2,0.0);
# Create properties, mappers, volume actors, and ray cast function
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty->SetScalarOpacity($opacityTransferFunction);
$volumeProperty->ShadeOn;
$compositeFunction = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetSize(600,300);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->SetBackground(0.1,0.2,0.4);
for ($i = 0; $i < 2; $i += 1)
 {
  for ($j = 0; $j < 4; $j += 1)
   {
    $volumeMapper__{$i} = Graphics::VTK::VolumeRayCastMapper->new($,'j');
    $volumeMapper__{$i}->_('j','SetInput',$reader->GetOutput);
    $volumeMapper__{$i}->_('j','SetVolumeRayCastFunction',$compositeFunction);
    $volumeMapper__{$i}->_('j','SetSampleDistance',0.4);
    $volumeMapper__{$i}->_('j','CroppingOn');
    $volumeMapper__{$i}->_('j','SetCroppingRegionPlanes',17,33,17,33,17,33);
    $volume__{$i} = Graphics::VTK::Volume->new($,'j');
    $volume__{$i}->_('j','SetMapper',$volumeMapper__{$i},$,'j');
    $volume__{$i}->_('j','SetProperty',$volumeProperty);
    $volume__{$i}->_('j','RotateX',30);
    $volume__{$i}->_('j','RotateY',30);
    $volume__{$i}->_('j','AddPosition',$j * 55,$i * 55,0);
    $ren1->AddProp($volume__{$i},$,'j');
   }
 }
$volumeMapper_0_0->SetCroppingRegionFlagsToSubVolume;
$volumeMapper_0_1->SetCroppingRegionFlagsToCross;
$volumeMapper_0_2->SetCroppingRegionFlagsToInvertedCross;
$volumeMapper_0_3->SetCroppingRegionFlags(24600);
$volumeMapper_1_0->SetCroppingRegionFlagsToFence;
$volumeMapper_1_1->SetCroppingRegionFlagsToInvertedFence;
$volumeMapper_1_2->SetCroppingRegionFlags(1);
$volumeMapper_1_3->SetCroppingRegionFlags(67117057);
$ren1->ResetCamera;
$ren1->GetActiveCamera->Zoom(3.0);
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
#renWin SetFileName "volTestClipRegions.tcl.ppm"
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
