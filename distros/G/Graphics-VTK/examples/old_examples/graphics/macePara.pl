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
# create a sphere source and actor
$sphere = Graphics::VTK::SphereSource->new;
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereActor = Graphics::VTK::LODActor->new;
$sphereActor->SetMapper($sphereMapper);
# create the spikes using a cone source and the sphere source
$cone = Graphics::VTK::ConeSource->new;
$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($sphere->GetOutput);
$glyph->SetSource($cone->GetOutput);
$glyph->SetVectorModeToUseNormal;
$glyph->SetScaleModeToScaleByVector;
$glyph->SetScaleFactor(0.25);
$spikeMapper = Graphics::VTK::PolyDataMapper->new;
$spikeMapper->SetInput($glyph->GetOutput);
$spikeActor = Graphics::VTK::LODActor->new;
$spikeActor->SetMapper($spikeMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($sphereActor);
$ren1->AddActor($spikeActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->ParallelProjectionOn;
$cam1->SetParallelScale(1);
$cam1->Zoom(1.4);
$iren->Initialize;
#renWin SetFileName "macePara.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
