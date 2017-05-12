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
$reader->SetFileName("$VTK_DATA/spring.slc");
# Create transfer functions for opacity and color
$opacityTransferFunction1 = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction1->AddPoint(60,0.0);
$opacityTransferFunction1->AddPoint(80,1.0);
$opacityTransferFunction2 = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction2->AddPoint(40,0.0);
$opacityTransferFunction2->AddPoint(100,0.5);
$opacityTransferFunction3 = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction3->AddPoint(20,0.0);
$opacityTransferFunction3->AddPoint(120,0.25);
$opacityTransferFunction4 = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction4->AddPoint(10,0.0);
$opacityTransferFunction4->AddPoint(150,0.1);
$colorTransferFunction1 = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction1->AddRGBPoint(0,1.0,0.0,0.0);
$colorTransferFunction1->AddRGBPoint(255,1.0,0.0,0.0);
$colorTransferFunction2 = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction2->AddRGBPoint(0,1.0,0.5,0.0);
$colorTransferFunction2->AddRGBPoint(255,1.0,0.5,0.0);
$colorTransferFunction3 = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction3->AddRGBPoint(0,1.0,1.0,0.0);
$colorTransferFunction3->AddRGBPoint(255,1.0,1.0,0.0);
$colorTransferFunction4 = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction4->AddRGBPoint(0,0.0,1.0,0.0);
$colorTransferFunction4->AddRGBPoint(255,0.0,1.0,0.0);
$colorTransferFunction5 = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction5->AddRGBPoint(0,0.0,0.0,1.0);
$colorTransferFunction5->AddRGBPoint(255,0.0,0.0,1.0);
$colorTransferFunction6 = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction6->AddRGBPoint(0,0.7,0.0,1.0);
$colorTransferFunction6->AddRGBPoint(255,0.7,0.0,1.0);
# Create properties, mappers, volume actors, and ray cast function
for ($i = 1; $i < 5; $i += 1)
 {
  for ($j = 1; $j < 7; $j += 1)
   {
    $volumeProperty = Graphics::VTK::VolumeProperty->new($,'i',$,'j');
    $volumeProperty->_('i',$,'j','ShadeOn');
    $volumeProperty->_('i',$,'j','SetInterpolationTypeToLinear');
    $volumeProperty->_('i',$,'j','SetColor',"colorTransferFunction$",'j');
    $volumeProperty->_('i',$,'j','SetScalarOpacity',"opacityTransferFunction$",'i');
   }
 }
$compositeFunction = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$volumeMapper = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper->SetInput($reader->GetOutput);
$volumeMapper->SetSampleDistance(0.25);
$volumeMapper->SetVolumeRayCastFunction($compositeFunction);
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetSize(256,256);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$rot = 0;
$tran = 0;
$scale = 1;
for ($i = 1; $i < 5; $i += 1)
 {
  for ($j = 1; $j < 7; $j += 1)
   {
    $volume = Graphics::VTK::Volume->new($,'i',$,'j');
    $volume->_('i',$,'j','SetMapper',$volumeMapper);
    $volume->_('i',$,'j','SetProperty',"volumeProperty$",'i',$,'j');
    $volume->_('i',$,'j','SetOrigin',23.5,0,23.5);
    $volume->_('i',$,'j','RotateX',$rot);
    $volume->_('i',$,'j','AddPosition',$tran,0,0);
    $volume->_('i',$,'j','SetScale',$scale);
    $ren1->AddVolume("volume$",'i',$,'j');
    $rot += 15;
    $tran += 47;
    $scale = $scale * 1.05;
   }
 }
$ren1->SetBackground('.1','.2','.4');
$ren1->GetActiveCamera->SetPosition(-8000,0,23.5);
$ren1->GetActiveCamera->SetFocalPoint(0,0,23.5);
$ren1->GetActiveCamera->SetClippingRange(100,2000);
$ren1->GetActiveCamera->SetViewPlaneNormal(-1,0,0);
$ren1->GetActiveCamera->SetViewUp(0,1,0);
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
$MW->withdraw;
$MW->update;
$ren1->GetActiveCamera->SetPosition(-800,0,23.5);
$renWin->Render;
#renWin SetFileName "valid/volRainbow.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
