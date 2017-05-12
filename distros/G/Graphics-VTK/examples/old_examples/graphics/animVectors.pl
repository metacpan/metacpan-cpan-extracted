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
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read data
$reader = Graphics::VTK::StructuredPointsReader->new;
$reader->SetFileName("$VTK_DATA/carotid.vtk");
$threshold = Graphics::VTK::ThresholdPoints->new;
$threshold->SetInput($reader->GetOutput);
$threshold->ThresholdByUpper(200);
$line = Graphics::VTK::LineSource->new;
$line->SetResolution(1);
$lines = Graphics::VTK::Glyph3D->new;
$lines->SetInput($threshold->GetOutput);
$lines->SetSource($line->GetOutput);
$lines->SetScaleFactor(0.005);
$lines->SetScaleModeToScaleByScalar;
$lines->Update;
#make range current
$vectorMapper = Graphics::VTK::PolyDataMapper->new;
$vectorMapper->SetInput($lines->GetOutput);
$vectorMapper->SetScalarRange($lines->GetOutput->GetScalarRange);
$vectorMapper->ImmediateModeRenderingOn;
$vectorActor = Graphics::VTK::Actor->new;
$vectorActor->SetMapper($vectorMapper);
$vectorActor->GetProperty->SetOpacity(0.99);
# 8 texture maps
$tmap1 = Graphics::VTK::StructuredPointsReader->new;
$tmap1->SetFileName("$VTK_DATA/vecTex/vecAnim1.vtk");
$texture1 = Graphics::VTK::Texture->new;
$texture1->SetInput($tmap1->GetOutput);
$texture1->InterpolateOff;
$texture1->RepeatOff;
$tmap2 = Graphics::VTK::StructuredPointsReader->new;
$tmap2->SetFileName("$VTK_DATA/vecTex/vecAnim2.vtk");
$texture2 = Graphics::VTK::Texture->new;
$texture2->SetInput($tmap2->GetOutput);
$texture2->InterpolateOff;
$texture2->RepeatOff;
$tmap3 = Graphics::VTK::StructuredPointsReader->new;
$tmap3->SetFileName("$VTK_DATA/vecTex/vecAnim3.vtk");
$texture3 = Graphics::VTK::Texture->new;
$texture3->SetInput($tmap3->GetOutput);
$texture3->InterpolateOff;
$texture3->RepeatOff;
$tmap4 = Graphics::VTK::StructuredPointsReader->new;
$tmap4->SetFileName("$VTK_DATA/vecTex/vecAnim4.vtk");
$texture4 = Graphics::VTK::Texture->new;
$texture4->SetInput($tmap4->GetOutput);
$texture4->InterpolateOff;
$texture4->RepeatOff;
$tmap5 = Graphics::VTK::StructuredPointsReader->new;
$tmap5->SetFileName("$VTK_DATA/vecTex/vecAnim5.vtk");
$texture5 = Graphics::VTK::Texture->new;
$texture5->SetInput($tmap5->GetOutput);
$texture5->InterpolateOff;
$texture5->RepeatOff;
$tmap6 = Graphics::VTK::StructuredPointsReader->new;
$tmap6->SetFileName("$VTK_DATA/vecTex/vecAnim6.vtk");
$texture6 = Graphics::VTK::Texture->new;
$texture6->SetInput($tmap6->GetOutput);
$texture6->InterpolateOff;
$texture6->RepeatOff;
$tmap7 = Graphics::VTK::StructuredPointsReader->new;
$tmap7->SetFileName("$VTK_DATA/vecTex/vecAnim7.vtk");
$texture7 = Graphics::VTK::Texture->new;
$texture7->SetInput($tmap7->GetOutput);
$texture7->InterpolateOff;
$texture7->RepeatOff;
$tmap8 = Graphics::VTK::StructuredPointsReader->new;
$tmap8->SetFileName("$VTK_DATA/vecTex/vecAnim8.vtk");
$texture8 = Graphics::VTK::Texture->new;
$texture8->SetInput($tmap8->GetOutput);
$texture8->InterpolateOff;
$texture8->RepeatOff;
$vectorActor->SetTexture($texture1);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($vectorActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(1.5);
$renWin->Render;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
# go into loop
for ($i = 0; $i < 5; $i += 1)
 {
  $vectorActor->SetTexture('texture1');
  $renWin->Render;
  $vectorActor->SetTexture('texture2');
  $renWin->Render;
  $vectorActor->SetTexture('texture3');
  $renWin->Render;
  $vectorActor->SetTexture('texture4');
  $renWin->Render;
  $vectorActor->SetTexture('texture5');
  $renWin->Render;
  $vectorActor->SetTexture('texture6');
  $renWin->Render;
  $vectorActor->SetTexture('texture7');
  $renWin->Render;
  $vectorActor->SetTexture('texture8');
  $renWin->Render;
  $vectorActor->SetTexture('texture1');
  $renWin->Render;
  $vectorActor->SetTexture('texture2');
  $renWin->Render;
  $vectorActor->SetTexture('texture3');
  $renWin->Render;
  $vectorActor->SetTexture('texture4');
  $renWin->Render;
  $vectorActor->SetTexture('texture5');
  $renWin->Render;
  $vectorActor->SetTexture('texture6');
  $renWin->Render;
  $vectorActor->SetTexture('texture7');
  $renWin->Render;
  $vectorActor->SetTexture('texture8');
  $renWin->Render;
 }
#renWin SetFileName animVectors.tcl.ppm
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
