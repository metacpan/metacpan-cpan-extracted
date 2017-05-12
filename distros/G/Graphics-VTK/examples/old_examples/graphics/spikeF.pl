#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of old spike-face
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a cyberware source
$cyber = Graphics::VTK::PolyDataReader->new;
$cyber->SetFileName("$VTK_DATA/fran_cut.vtk");
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetMaxRecursionDepth(100);
$normals->SetInput($cyber->GetOutput);
$cyberMapper = Graphics::VTK::PolyDataMapper->new;
$cyberMapper->SetInput($normals->GetOutput);
$cyberActor = Graphics::VTK::Actor->new;
$cyberActor->SetMapper($cyberMapper);
$cyberActor->GetProperty->SetColor(1.0,0.49,0.25);
# create the spikes using a cone source and a subset of cyber points
$ptMask = Graphics::VTK::MaskPoints->new;
$ptMask->SetInput($normals->GetOutput);
$ptMask->SetOnRatio(100);
$ptMask->RandomModeOn;
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(6);
$transform = Graphics::VTK::Transform->new;
$transform->Translate(0.5,0.0,0.0);
$transformF = Graphics::VTK::TransformPolyDataFilter->new;
$transformF->SetInput($cone->GetOutput);
$transformF->SetTransform($transform);
$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($ptMask->GetOutput);
$glyph->SetSource($transformF->GetOutput);
$glyph->SetVectorModeToUseNormal;
$glyph->SetScaleModeToScaleByVector;
$glyph->SetScaleFactor(0.004);
$spikeMapper = Graphics::VTK::PolyDataMapper->new;
$spikeMapper->SetInput($glyph->GetOutput);
$spikeActor = Graphics::VTK::Actor->new;
$spikeActor->SetMapper($spikeMapper);
$spikeActor->GetProperty->SetColor(0.0,0.79,0.34);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($cyberActor);
$ren1->AddActor($spikeActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
#renWin SetSize 1000 1000
$ren1->SetBackground(0.1,0.2,0.4);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$sphereProp = $cyberActor->GetProperty;
$spikeProp = $spikeActor->GetProperty;
# do stereo example
$cam1->Zoom(1.4);
$cam1->Azimuth(110);
$renWin->Render;
$renWin->SetFileName("valid/spikeF.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
