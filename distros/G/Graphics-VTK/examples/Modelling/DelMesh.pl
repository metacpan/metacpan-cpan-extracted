#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates how to use 2D Delaunay triangulation.
# We create a fancy image of a 2D Delaunay triangulation. Points are 
# randomly generated.


# first we load in the standard vtk packages into tcl
$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;

# Generate some random points

$math = Graphics::VTK::Math->new;
$points = Graphics::VTK::Points->new;
for ($i = 0; $i < 50; $i += 1)
 {
  $points->InsertPoint($i,$math->Random(0,1),$math->Random(0,1),0.0);
 }

# Create a polydata with the points we just created.
$profile = Graphics::VTK::PolyData->new;
$profile->SetPoints($points);

# Perform a 2D Delaunay triangulation on them.

$del = Graphics::VTK::Delaunay2D->new;
$del->SetInput($profile);
$del->SetTolerance(0.001);
$mapMesh = Graphics::VTK::PolyDataMapper->new;
$mapMesh->SetInput($del->GetOutput);
$meshActor = Graphics::VTK::Actor->new;
$meshActor->SetMapper($mapMesh);
$meshActor->GetProperty->SetColor('.1','.2','.4');

# We will now create a nice looking mesh by wrapping the edges in tubes,
# and putting fat spheres at the points.
$extract = Graphics::VTK::ExtractEdges->new;
$extract->SetInput($del->GetOutput);
$tubes = Graphics::VTK::TubeFilter->new;
$tubes->SetInput($extract->GetOutput);
$tubes->SetRadius(0.01);
$tubes->SetNumberOfSides(6);
$mapEdges = Graphics::VTK::PolyDataMapper->new;
$mapEdges->SetInput($tubes->GetOutput);
$edgeActor = Graphics::VTK::Actor->new;
$edgeActor->SetMapper($mapEdges);
$edgeActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$edgeActor->GetProperty->SetSpecularColor(1,1,1);
$edgeActor->GetProperty->SetSpecular(0.3);
$edgeActor->GetProperty->SetSpecularPower(20);
$edgeActor->GetProperty->SetAmbient(0.2);
$edgeActor->GetProperty->SetDiffuse(0.8);

$ball = Graphics::VTK::SphereSource->new;
$ball->SetRadius(0.025);
$ball->SetThetaResolution(12);
$ball->SetPhiResolution(12);
$balls = Graphics::VTK::Glyph3D->new;
$balls->SetInput($del->GetOutput);
$balls->SetSource($ball->GetOutput);
$mapBalls = Graphics::VTK::PolyDataMapper->new;
$mapBalls->SetInput($balls->GetOutput);
$ballActor = Graphics::VTK::Actor->new;
$ballActor->SetMapper($mapBalls);
$ballActor->GetProperty->SetColor(@Graphics::VTK::Colors::hot_pink);
$ballActor->GetProperty->SetSpecularColor(1,1,1);
$ballActor->GetProperty->SetSpecular(0.3);
$ballActor->GetProperty->SetSpecularPower(20);
$ballActor->GetProperty->SetAmbient(0.2);
$ballActor->GetProperty->SetDiffuse(0.8);

# Create graphics objects
# Create the rendering window, renderer, and interactive renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size
$ren1->AddActor($ballActor);
$ren1->AddActor($edgeActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(150,150);

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(1.5);
$iren->Initialize;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;


Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
