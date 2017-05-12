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
$opacityTransferFunction->AddPoint(20,0.0);
$opacityTransferFunction->AddPoint(255,0.2);
$colorTransferFunction = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction->AddRGBPoint(0.0,0.0,0.0,0.0);
$colorTransferFunction->AddRGBPoint(64.0,1.0,0.0,0.0);
$colorTransferFunction->AddRGBPoint(128.0,0.0,0.0,1.0);
$colorTransferFunction->AddRGBPoint(192.0,0.0,1.0,0.0);
$colorTransferFunction->AddRGBPoint(255.0,0.0,0.2,0.0);
# Create properties, mappers, volume actors, and ray cast function
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetColor($colorTransferFunction);
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
#renWin SetFileName "valid/volSimple.ppm"
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
