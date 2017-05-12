#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Test butterfly subdivision of point data
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetPhiResolution(11);
$sphere->SetThetaResolution(11);
$colorIt = Graphics::VTK::ElevationFilter->new;
$colorIt->SetInput($sphere->GetOutput);
$colorIt->SetLowPoint(0,0,'-.5');
$colorIt->SetHighPoint(0,0,'.5');
$butterfly = Graphics::VTK::ButterflySubdivisionFilter->new;
$butterfly->SetInput($colorIt->GetPolyDataOutput);
$butterfly->SetNumberOfSubdivisions(3);
$lut = Graphics::VTK::LookupTable->new;
$lut->SetNumberOfColors(256);
$lut->Build;
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($butterfly->GetOutput);
$mapper->SetLookupTable($lut);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$linear = Graphics::VTK::LinearSubdivisionFilter->new;
$linear->SetInput($colorIt->GetPolyDataOutput);
$linear->SetNumberOfSubdivisions(3);
$mapper2 = Graphics::VTK::PolyDataMapper->new;
$mapper2->SetInput($linear->GetOutput);
$mapper2->SetLookupTable($lut);
$actor2 = Graphics::VTK::Actor->new;
$actor2->SetMapper($mapper2);
$mapper3 = Graphics::VTK::PolyDataMapper->new;
$mapper3->SetInput($colorIt->GetOutput);
$mapper3->SetLookupTable($lut);
$actor3 = Graphics::VTK::Actor->new;
$actor3->SetMapper($mapper3);
$ren1 = Graphics::VTK::Renderer->new;
$ren2 = Graphics::VTK::Renderer->new;
$ren3 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->AddRenderer($ren2);
$renWin->AddRenderer($ren3);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($actor);
$ren1->SetBackground(1,1,1);
$ren2->AddActor($actor2);
$ren2->SetBackground(1,1,1);
$ren3->AddActor($actor3);
$ren3->SetBackground(1,1,1);
$renWin->SetSize(600,200);
$aCamera = Graphics::VTK::Camera->new;
$aCamera->Azimuth(70);
$aLight = Graphics::VTK::Light->new;
$aLight->SetPosition($aCamera->GetPosition);
$aLight->SetFocalPoint($aCamera->GetFocalPoint);
$ren1->SetActiveCamera($aCamera);
$ren1->AddLight($aLight);
$ren1->ResetCamera;
$aCamera->Dolly(1.4);
$ren1->ResetCameraClippingRange;
$ren2->SetActiveCamera($aCamera);
$ren2->AddLight($aLight);
$ren3->SetActiveCamera($aCamera);
$ren3->AddLight($aLight);
$ren3->SetViewport(0,0,'.33',1);
$ren2->SetViewport('.33',0,'.67',1);
$ren1->SetViewport('.67',0,1,1);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#
sub flat
{
 $actor->GetProperty->SetInterpolationToFlat;
 $actor2->GetProperty->SetInterpolationToFlat;
 $actor3->GetProperty->SetInterpolationToFlat;
 $renWin->Render;
}
#
sub smooth
{
 $actor->GetProperty->SetInterpolationToGouraud;
 $actor2->GetProperty->SetInterpolationToGouraud;
 $actor3->GetProperty->SetInterpolationToGouraud;
 $renWin->Render;
}
$renWin->SetFileName('subdividePointData.tcl.ppm');
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
