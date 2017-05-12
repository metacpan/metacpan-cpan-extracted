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
# create some random points in the unit cube centered at (.5,.5,.5)
$math = Graphics::VTK::Math->new;
$points = Graphics::VTK::Points->new;
for ($i = 0; $i < 25; $i += 1)
 {
  $points->InsertPoint($i,$math->Random(0,1),$math->Random(0,1),$math->Random(0,1));
 }
$profile = Graphics::VTK::PolyData->new;
$profile->SetPoints($points);
# triangulate them
$del = Graphics::VTK::Delaunay3D->new;
$del->SetInput($profile);
$del->BoundingTriangulationOn;
$del->SetTolerance(0.01);
$del->SetAlpha(0.2);
$del->BoundingTriangulationOff;
$shrink = Graphics::VTK::ShrinkFilter->new;
$shrink->SetInput($del->GetOutput);
$shrink->SetShrinkFactor(0.9);
$map = Graphics::VTK::DataSetMapper->new;
$map->SetInput($shrink->GetOutput);
$triangulation = Graphics::VTK::Actor->new;
$triangulation->SetMapper($map);
$triangulation->GetProperty->SetColor(1,0,0);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($triangulation);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$renWin->Render;
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.5);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName Delaunay3D.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
