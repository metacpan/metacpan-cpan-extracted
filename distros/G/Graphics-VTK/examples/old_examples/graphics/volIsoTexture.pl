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
$reader->SetFileName("$VTK_DATA/nut.slc");
$rgbreader = Graphics::VTK::StructuredPointsReader->new;
$rgbreader->SetFileName("$VTK_DATA/hipipTexture.vtk");
# Create transfer functions for opacity and color
$opacityTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction->AddPoint(100,0.0);
$opacityTransferFunction->AddPoint(128,1.0);
$colorTransferFunction = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction->AddRGBPoint(0,1.0,1.0,1.0);
$colorTransferFunction->AddRGBPoint(255,1.0,1.0,1.0);
# Create properties, mappers, volume actors, and ray cast function
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty->SetScalarOpacity($opacityTransferFunction);
$volumeProperty->ShadeOn;
$volumeProperty->SetInterpolationTypeToLinear;
$isoFunction = Graphics::VTK::VolumeRayCastIsosurfaceFunction->new;
$isoFunction->SetIsoValue(128.0);
$volumeMapper = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper->SetInput($reader->GetOutput);
$volumeMapper->SetRGBTextureInput($rgbreader->GetOutput);
$volumeMapper->SetVolumeRayCastFunction($isoFunction);
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
$renWin->SetSize(200,200);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
#ren1 AddActor outlineActor
$ren1->AddVolume($volume);
$ren1->SetBackground(0.1,0.2,0.4);
$ren1->GetActiveCamera->Elevation(30.0);
$ren1->GetActiveCamera->Zoom(1.3);
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
for ($i = 0.1; $i <= 0.8; $i = $i + 0.1)
 {
  $volumeProperty->SetRGBTextureCoefficient($i);
  $renWin->Render;
 }
for ($i = 0; $i <= 12; $i += 2)
 {
  $rgbreader->GetOutput->SetOrigin($i,$i,$i);
  $renWin->Render;
 }
#renWin SetFileName "valid/volIsoTexture.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
