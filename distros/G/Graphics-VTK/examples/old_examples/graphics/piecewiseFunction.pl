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
$reader->SetFileName("$VTK_DATA/poship.slc");
# Create transfer functions for opacity and color
$opacityTransferFunction = Graphics::VTK::PiecewiseFunction->new;
# Get a value of the function when no points are defined
$opacityTransferFunction->GetValue(50);
# Exceed the initial size of the piecewise function (64)
for ($i = 0; $i < 64; $i += 1)
 {
  $opacityTransferFunction->AddPoint($i,$i / 128.0);
 }
for ((); $i < 128; $i += 1)
 {
  $opacityTransferFunction->AddPoint($i,'.5' - ($i / 128.0));
 }
# Add a segment
$opacityTransferFunction->AddSegment(128,0,256,0);
$opacityTransferFunction->AddSegment(256,0,128,0);
# Delete first point
$opacityTransferFunction->RemovePoint(0);
# Duplicate an entry
$opacityTransferFunction->AddPoint(64,'.55');
# Add a point at the start
$opacityTransferFunction->AddPoint(-1,100);
# Get the value of the function at a point outside the set values
$opacityTransferFunction->GetValue(640);
# Turn clamping off
$opacityTransferFunction->ClampingOff;
# Get the value of the function at a point outside the set values
$opacityTransferFunction->GetValue(640);
# Turn clamping back on
$opacityTransferFunction->ClampingOn;
# Remove all points created so far
$opacityTransferFunction->RemoveAllPoints;
# Create a final transfer function for volume rendering
$opacityTransferFunction->AddPoint(20,0.0);
$opacityTransferFunction->AddPoint(255,0.2);
$colorTransferFunction = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction->AddRedPoint(0.0,0.0);
$colorTransferFunction->AddRedPoint(64.0,1.0);
$colorTransferFunction->AddRedPoint(128.0,0.0);
$colorTransferFunction->AddRedPoint(255.0,0.0);
$colorTransferFunction->AddBluePoint(0.0,0.0);
$colorTransferFunction->AddBluePoint(64.0,0.0);
$colorTransferFunction->AddBluePoint(128.0,1.0);
$colorTransferFunction->AddBluePoint(192.0,0.0);
$colorTransferFunction->AddBluePoint(255.0,0.0);
$colorTransferFunction->AddGreenPoint(0.0,0.0);
$colorTransferFunction->AddGreenPoint(128.0,0.0);
$colorTransferFunction->AddGreenPoint(192.0,1.0);
$colorTransferFunction->AddGreenPoint(255.0,0.2);
# Create properties, mappers, volume actors, and ray cast function
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty->SetScalarOpacity($opacityTransferFunction);
$compositeFunction = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$volumeMapper = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper->SetInput($reader->GetOutput);
$volumeMapper->SetVolumeRayCastFunction($compositeFunction);
$volume = Graphics::VTK::Volume->new;
$volume->SetMapper($volumeMapper);
$volume->SetProperty($volumeProperty);
# Create outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(1,1,1);
# Okay now the graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetSize(256,256);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
#ren1 AddActor outlineActor
$ren1->AddVolume($volume);
$ren1->SetBackground(0.1,0.2,0.4);
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
#renWin SetFileName "valid/piecewiseFunction.ppm"
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
