#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# user interface command widget
use Graphics::VTK::Tk::vtkInt;
# create a rendering window and renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->StereoCapableWindowOn;
# create an actor and give it cone geometry
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(8);
$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($cone->GetOutput);
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);
# assign our actor to the renderer
$ren1->AddActor($coneActor);
$renWin->Render;
$w2if = Graphics::VTK::WindowToImageFilter->new;
$w2if->SetInput($renWin);
$imgDiff = Graphics::VTK::ImageDifference->new;
$rtpnm = Graphics::VTK::PNMReader->new;
$rtpnm->SetFileName("valid/Cone.tcl.ppm");
$imgDiff->SetInput($w2if->GetOutput);
$imgDiff->SetImage($rtpnm->GetOutput);
$imgDiff->Update;
if ($imgDiff->GetThresholdedError <= 10)
 {
  print("Tcl smoke test passed.");
 }
else
 {
  print("Tcl smoke test failed.");
 }
$MW->withdraw;
exit();
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
