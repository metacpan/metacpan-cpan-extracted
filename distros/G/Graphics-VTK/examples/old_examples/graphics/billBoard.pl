#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Create a rolling billboard - requires texture support
# Get the interactor
use Graphics::VTK::Tk::vtkInt;
# load in the texture map
$pnmReader = Graphics::VTK::PNMReader->new;
$pnmReader->SetFileName("$VTK_DATA/billBoard.pgm");
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($pnmReader->GetOutput);
$atext->InterpolateOn;
# create a plane source and actor
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetPoint1(1024,0,0);
$plane->SetPoint2(0,64,0);
$trans = Graphics::VTK::TransformTextureCoords->new;
$trans->SetInput($plane->GetOutput);
$planeMapper = Graphics::VTK::DataSetMapper->new;
$planeMapper->SetInput($trans->GetOutput);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$planeActor->SetTexture($atext);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($planeActor);
$ren1->SetBackground(0.1,0.2,0.4);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetSize(512,32);
# Setup camera
$camera = Graphics::VTK::Camera->new;
$camera->SetClippingRange(11.8369,591.843);
#  camera SetFocalPoint 512 32 0
$camera->SetPosition(512,32,118.369);
$camera->SetViewAngle(30);
$camera->SetViewPlaneNormal(0,0,1);
$camera->SetDistance(118.369);
$camera->SetViewUp(0,1,0);
$ren1->SetActiveCamera($camera);
$renWin->Render;
for ($i = 0; $i < 112; $i += 1)
 {
  $trans->AddPosition(0.01,0,0);
  $renWin->Render;
 }
for ($i = 0; $i < 40; $i += 1)
 {
  $trans->AddPosition(0,0.05,0);
  $renWin->Render;
 }
for ($i = 0; $i < 112; $i += 1)
 {
  $trans->AddPosition(-0.01,0,0);
  $renWin->Render;
 }
#renWin SetFileName billBoard.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
