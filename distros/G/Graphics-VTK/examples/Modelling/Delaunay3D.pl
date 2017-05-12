#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example shows how to use Delaunay3D with alpha shapes.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# The points to be triangulated are generated randomly in the unit cube
# located at the origin. The points are then associated with a vtkPolyData.

$math = Graphics::VTK::Math->new;
$points = Graphics::VTK::Points->new;
for ($i = 0; $i < 25; $i += 1)
 {
  $points->InsertPoint($i,$math->Random(0,1),$math->Random(0,1),$math->Random(0,1));
 }

$profile = Graphics::VTK::PolyData->new;
$profile->SetPoints($points);

# Delaunay3D is used to triangulate the points. The Tolerance is the distance
# that nearly coincident points are merged together. (Delaunay does better if
# points are well spaced.) The alpha value is the radius of circumcircles,
# circumspheres. Any mesh entity whose circumcircle is smaller than this
# value is output.

$del = Graphics::VTK::Delaunay3D->new;
$del->SetInput($profile);
$del->SetTolerance(0.01);
$del->SetAlpha(0.2);
$del->BoundingTriangulationOff;

# Shrink the result to help see it better.
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
$renWin->SetSize(250,250);
$renWin->Render;

$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.5);

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;



Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
