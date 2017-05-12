#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Volume rendering example with multiple lights
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$reader = Graphics::VTK::SLCReader->new;
$reader->SetFileName("$VTK_DATA/sphere.slc");
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
$volumeProperty->SetDiffuse(0.7);
$volumeProperty->SetAmbient(0.01);
$volumeProperty->SetSpecular(0.5);
$volumeProperty->SetSpecularPower(70.0);
$compositeFunction = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$volumeMapper = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper->SetInput($reader->GetOutput);
$volumeMapper->SetVolumeRayCastFunction($compositeFunction);
$volume = Graphics::VTK::Volume->new;
$volume->SetMapper($volumeMapper);
$volume->SetProperty($volumeProperty);
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetSize(256,256);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetRadius(20);
$sphere->SetCenter(70,25,25);
$sphere->SetThetaResolution(50);
$sphere->SetPhiResolution(50);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($sphere->GetOutput);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$actor->GetProperty->SetColor(1,1,1);
$actor->GetProperty->SetAmbient(0.01);
$actor->GetProperty->SetDiffuse(0.7);
$actor->GetProperty->SetSpecular(0.5);
$actor->GetProperty->SetSpecularPower(70.0);
$ren1->AddVolume($volume);
$ren1->AddActor($actor);
$ren1->SetBackground(0.1,0.2,0.4);
$ren1->GetActiveCamera->Zoom(1.6);
$renWin->Render;
$lights = $ren1->GetLights;
$lights->InitTraversal;
$light = $lights->GetNextItem;
$light->SetIntensity(0.7);
$redlight = Graphics::VTK::Light->new;
$redlight->SetColor(1,0,0);
$redlight->SetPosition(1000,25,25);
$redlight->SetFocalPoint(25,25,25);
$redlight->SetIntensity(0.5);
$greenlight = Graphics::VTK::Light->new;
$greenlight->SetColor(0,1,0);
$greenlight->SetPosition(25,1000,25);
$greenlight->SetFocalPoint(25,25,25);
$greenlight->SetIntensity(0.5);
$bluelight = Graphics::VTK::Light->new;
$bluelight->SetColor(0,0,1);
$bluelight->SetPosition(25,25,1000);
$bluelight->SetFocalPoint(25,25,25);
$bluelight->SetIntensity(0.5);
$ren1->AddLight($redlight);
$ren1->AddLight($greenlight);
$ren1->AddLight($bluelight);
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
#renWin SetFileName "valid/volMultiLight.tcl.ppm"
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
