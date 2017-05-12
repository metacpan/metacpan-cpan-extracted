#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This version of TPlane.tcl exercises the texture release mechanism.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$light = Graphics::VTK::Light->new;
$ren1->AddLight($light);
# create a plane source and actor
$plane = Graphics::VTK::PlaneSource->new;
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($plane->GetOutput);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
# load in the texture map
$atext = Graphics::VTK::Texture->new;
$pnmReader = Graphics::VTK::PNMReader->new;
$pnmReader->SetFileName("$VTK_DATA/masonry.ppm");
$atext->SetInput($pnmReader->GetOutput);
$atext->InterpolateOn;
$planeActor->SetTexture($atext);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($planeActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);
# render the image
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$cam1 = $ren1->GetActiveCamera;
$cam1->Elevation(-30);
$cam1->Roll(-20);
$ren1->ResetCameraClippingRange;
$renWin->Render;
$fooTexture = Graphics::VTK::Texture->new;
$fooTexture->SetInput($pnmReader->GetOutput);
for ($i = 0; $i < 72; $i += 1)
 {
  $planeActor->SetTexture($fooTexture);
  $atext->ReleaseGraphicsResources($renWin);

  $atext = Graphics::VTK::Texture->new;
  $atext->SetInput($pnmReader->GetOutput);
  $atext->InterpolateOn;
  $planeActor->SetTexture($atext);
  $ren1->GetActiveCamera->Azimuth(5);
  $light->SetFocalPoint($ren1->GetActiveCamera->GetFocalPoint);
  $light->SetPosition($ren1->GetActiveCamera->GetPosition);
  $ren1->ResetCameraClippingRange;
  $renWin->Render;
 }
#renWin SetFileName "TPlane2.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
