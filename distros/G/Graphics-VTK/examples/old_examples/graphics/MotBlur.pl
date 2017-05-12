#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of the Mace example
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create the piplinee, ball and spikes
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetThetaResolution(7);
$sphere->SetPhiResolution(7);
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);
$sphereActor2 = Graphics::VTK::Actor->new;
$sphereActor2->SetMapper($sphereMapper);
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(5);
$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($sphere->GetOutput);
$glyph->SetSource($cone->GetOutput);
$glyph->SetVectorModeToUseNormal;
$glyph->SetScaleModeToScaleByVector;
$glyph->SetScaleFactor(0.25);
$spikeMapper = Graphics::VTK::PolyDataMapper->new;
$spikeMapper->SetInput($glyph->GetOutput);
$spikeActor = Graphics::VTK::Actor->new;
$spikeActor->SetMapper($spikeMapper);
$spikeActor2 = Graphics::VTK::Actor->new;
$spikeActor2->SetMapper($spikeMapper);
$spikeActor->SetPosition(0,0.7,0);
$sphereActor->SetPosition(0,0.7,0);
$spikeActor2->SetPosition(0,-0.7,0);
$sphereActor2->SetPosition(0,-0.7,0);
$ren1->AddActor($sphereActor);
$ren1->AddActor($spikeActor);
$ren1->AddActor($sphereActor2);
$ren1->AddActor($spikeActor2);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(200,200);
$renWin->DoubleBufferOn;
# do the first render and then zoom in a little
$renWin->Render;
$ren1->GetActiveCamera->Zoom(1.5);
$iren->Initialize;
$renWin->SetSubFrames(21);
for ($i = 0; $i <= 1.0; $i = $i + 0.05)
 {
  $spikeActor2->RotateY(2);
  $sphereActor2->RotateY(2);
  $renWin->Render;
 }
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName MotBlur.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
