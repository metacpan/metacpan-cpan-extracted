#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# use implicit modeller / interpolation to perform 3D morphing
use Graphics::VTK::Tk::vtkInt;
# get some nice colors
use Graphics::VTK::Colors;
# make the letter v
$letterV = Graphics::VTK::VectorText->new;
$letterV->SetText('v');
# read the geometry file containing the letter t
$letterT = Graphics::VTK::VectorText->new;
$letterT->SetText('t');
# read the geometry file containing the letter k
$letterK = Graphics::VTK::VectorText->new;
$letterK->SetText('k');
# create implicit models of each
$blobbyV = Graphics::VTK::ImplicitModeller->new;
$blobbyV->SetInput($letterV->GetOutput);
$blobbyV->SetMaximumDistance('.2');
$blobbyV->SetSampleDimensions(50,50,12);
$blobbyV->SetModelBounds(-0.5,1.5,-0.5,1.5,-0.5,0.5);
# create implicit models of each
$blobbyT = Graphics::VTK::ImplicitModeller->new;
$blobbyT->SetInput($letterT->GetOutput);
$blobbyT->SetMaximumDistance('.2');
$blobbyT->SetSampleDimensions(50,50,12);
$blobbyT->SetModelBounds(-0.5,1.5,-0.5,1.5,-0.5,0.5);
# create implicit models of each
$blobbyK = Graphics::VTK::ImplicitModeller->new;
$blobbyK->SetInput($letterK->GetOutput);
$blobbyK->SetMaximumDistance('.2');
$blobbyK->SetSampleDimensions(50,50,12);
$blobbyK->SetModelBounds(-0.5,1.5,-0.5,1.5,-0.5,0.5);
# Interpolate the data
$interpolate = Graphics::VTK::InterpolateDataSetAttributes->new;
$interpolate->AddInput($blobbyV->GetOutput);
$interpolate->AddInput($blobbyT->GetOutput);
$interpolate->AddInput($blobbyK->GetOutput);
$interpolate->SetT(0.0);
# extract an iso surface
$blobbyIso = Graphics::VTK::ContourFilter->new;
$blobbyIso->SetInput($interpolate->GetOutput);
$blobbyIso->SetValue(0,0.1);
# map to rendering primitives
$blobbyMapper = Graphics::VTK::PolyDataMapper->new;
$blobbyMapper->SetInput($blobbyIso->GetOutput);
$blobbyMapper->ScalarVisibilityOff;
# now an actor
$blobby = Graphics::VTK::Actor->new;
$blobby->SetMapper($blobbyMapper);
$blobby->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::banana);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$camera = Graphics::VTK::Camera->new;
$camera->SetClippingRange(0.265,13.2);
$camera->SetFocalPoint(0.539,0.47464,0);
$camera->SetPosition(0.539,0.474674,2.644);
$camera->ComputeViewPlaneNormal;
$camera->SetViewUp(0,1,0);
$ren1->SetActiveCamera($camera);
#  now  make a renderer and tell it about lights and actors
$renWin->SetSize(300,350);
$ren1->AddActor($blobby);
$ren1->SetBackground(1,1,1);
$renWin->Render;
$subIters = 20.0;
for ($i = 0; $i < 2; $i += 1)
 {
  for ($j = 1; $j <= $subIters; $j += 1)
   {
    $t = $i + $j / $subIters;
    $interpolate->SetT($t);
    $renWin->Render;
   }
 }
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
