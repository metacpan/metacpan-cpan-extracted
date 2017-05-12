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
$colorTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$colorTransferFunction->AddPoint(0.0,0.0);
$colorTransferFunction->AddPoint(64.0,1.0);
$colorTransferFunction->AddPoint(128.0,0.0);
$colorTransferFunction->AddPoint(255.0,0.0);
# Create properties, mappers, volume actors, and ray cast function
$volumeProperty1 = Graphics::VTK::VolumeProperty->new;
$volumeProperty1->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty1->SetScalarOpacity($opacityTransferFunction);
$volumeProperty1->SetInterpolationTypeToLinear;
$volumeProperty1->ShadeOn;
$volumeProperty2 = Graphics::VTK::VolumeProperty->new;
$volumeProperty2->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty2->SetScalarOpacity($opacityTransferFunction);
$volumeProperty2->SetInterpolationTypeToLinear;
$volumeProperty2->ShadeOff;
$volumeProperty3 = Graphics::VTK::VolumeProperty->new;
$volumeProperty3->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty3->SetScalarOpacity($opacityTransferFunction);
$volumeProperty3->SetInterpolationTypeToNearest;
$volumeProperty3->ShadeOn;
$volumeProperty4 = Graphics::VTK::VolumeProperty->new;
$volumeProperty4->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty4->SetScalarOpacity($opacityTransferFunction);
$volumeProperty4->SetInterpolationTypeToNearest;
$volumeProperty4->ShadeOff;
$compositeFunction = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$volumeMapper = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper->SetInput($reader->GetOutput);
$volumeMapper->SetVolumeRayCastFunction($compositeFunction);
$volume1 = Graphics::VTK::Volume->new;
$volume1->SetMapper($volumeMapper);
$volume1->SetProperty($volumeProperty1);
$volume2 = Graphics::VTK::Volume->new;
$volume2->SetMapper($volumeMapper);
$volume2->SetProperty($volumeProperty2);
$volume3 = Graphics::VTK::Volume->new;
$volume3->SetMapper($volumeMapper);
$volume3->SetProperty($volumeProperty3);
$volume4 = Graphics::VTK::Volume->new;
$volume4->SetMapper($volumeMapper);
$volume4->SetProperty($volumeProperty4);
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
$ren1->SetViewport(0,0,'.5','.5');
$ren2 = Graphics::VTK::Renderer->new;
$ren2->SetViewport('.5',0,1.0,'.5');
$ren3 = Graphics::VTK::Renderer->new;
$ren3->SetViewport(0,'.5','.5',1);
$ren4 = Graphics::VTK::Renderer->new;
$ren4->SetViewport('.5','.5',1,1);
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->AddRenderer($ren2);
$renWin->AddRenderer($ren3);
$renWin->AddRenderer($ren4);
$renWin->SetSize(256,256);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($outlineActor);
$ren2->AddActor($outlineActor);
$ren3->AddActor($outlineActor);
$ren4->AddActor($outlineActor);
$ren1->AddVolume($volume1);
$ren2->AddVolume($volume2);
$ren3->AddVolume($volume3);
$ren4->AddVolume($volume4);
# Render the unshaded volume
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
#renWin SetFileName "valid/volExercise.tcl.ppm"
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
