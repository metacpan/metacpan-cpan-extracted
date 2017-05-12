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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create some points
$math = Graphics::VTK::Math->new;
$points = Graphics::VTK::Points->new;
for ($i = 0; $i < 50; $i += 1)
 {
  $points->InsertPoint($i,$math->Random(0,1),$math->Random(0,1),$math->Random(0,1));
 }
$scalars = Graphics::VTK::Scalars->new;
for ($i = 0; $i < 50; $i += 1)
 {
  $scalars->InsertScalar($i,$math->Random(0,1));
 }
$profile = Graphics::VTK::PolyData->new;
$profile->SetPoints($points);
$profile->GetPointData->SetScalars($scalars);
# triangulate them
$shepard = Graphics::VTK::ShepardMethod->new;
$shepard->SetInput($profile);
$shepard->SetModelBounds(0,1,0,1,'.1','.5');
#    shepard SetMaximumDistance .1
$shepard->SetNullValue(1);
$shepard->SetSampleDimensions(20,20,20);
$shepard->Update;
$map = Graphics::VTK::DataSetMapper->new;
$map->SetInput($shepard->GetOutput);
$block = Graphics::VTK::Actor->new;
$block->SetMapper($map);
$block->GetProperty->SetColor(1,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($block);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$cam1 = $ren1->GetActiveCamera;
$cam1->Azimuth(160);
$cam1->Elevation(30);
$cam1->Zoom(1.5);
$ren1->ResetCameraClippingRange;
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName shepards.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
