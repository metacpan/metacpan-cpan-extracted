#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$reader = Graphics::VTK::SLCReader->new;
$reader->SetFileName("$VTK_DATA/poship.slc");
$reader2 = Graphics::VTK::SLCReader->new;
$reader2->SetFileName("$VTK_DATA/neghip.slc");
$opacityTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction->AddPoint(20,0.0);
$opacityTransferFunction->AddPoint(255,0.3);
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
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty->SetScalarOpacity($opacityTransferFunction);
$volumeProperty->SetInterpolationTypeToLinear;
$volumeProperty->ShadeOn;
$MIPFunction = Graphics::VTK::VolumeRayCastMIPFunction->new;
$volumeMapper = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper->SetInput($reader->GetOutput);
$volumeMapper->SetVolumeRayCastFunction($MIPFunction);
$volumeMapper->SetSampleDistance(0.25);
$volume = Graphics::VTK::Volume->new;
$volume->SetMapper($volumeMapper);
$volume->SetProperty($volumeProperty);
$contour = Graphics::VTK::ContourFilter->new;
$contour->SetInput($reader2->GetOutput);
$contour->SetValue(0,128.0);
$neghip_mapper = Graphics::VTK::PolyDataMapper->new;
$neghip_mapper->SetInput($contour->GetOutput);
$neghip_mapper->ScalarVisibilityOff;
$neghip = Graphics::VTK::Actor->new;
$neghip->SetMapper($neghip_mapper);
$neghip->GetProperty->SetColor(0.8,0.2,0.8);
$neghip->GetProperty->SetAmbient(0.1);
$neghip->GetProperty->SetDiffuse(0.6);
$neghip->GetProperty->SetSpecular(0.4);
# Okay now the graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$ren1->SetBackground(0.1,0.2,0.4);
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetSize(256,256);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($neghip);
$ren1->SetBackground(0,0,0);
$ren1->GetActiveCamera->SetPosition(162.764,30.8946,116.029);
$ren1->GetActiveCamera->SetFocalPoint(32.868,31.5566,31.9246);
$ren1->GetActiveCamera->SetViewUp(-0.00727828,0.999791,0.0191114);
$ren1->GetActiveCamera->SetViewPlaneNormal(0.839404,-0.00427837,0.543492);
$ren1->GetActiveCamera->SetClippingRange(15.4748,773.74);
$ren1->AddVolume($volume);
$renWin->SetSize(200,200);
$renWin->Render;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->SetDesiredUpdateRate(1);
$iren->Initialize;
#renWin SetFileName "VolMIP.tcl.ppm"
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
