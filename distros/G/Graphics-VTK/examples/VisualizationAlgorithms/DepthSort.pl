#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of vtkDepthSortPolyData. This is a 
# poor man's algorithm to sort polygons for proper transparent blending.
# It sorts polygons based on a single point (i.e., centroid) so the sorting
# may not work for overlapping or intersection polygons.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Create a bunch of spheres that overlap and cannot be easily arranged
# so that the blending works without sorting. They are appended into a
# single vtkPolyData because the filter only sorts within a single 
# vtkPolyData input.

$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetThetaResolution(80);
$sphere->SetPhiResolution(40);
$sphere->SetRadius(1);
$sphere->SetCenter(0,0,0);
$sphere2 = Graphics::VTK::SphereSource->new;
$sphere2->SetThetaResolution(80);
$sphere2->SetPhiResolution(40);
$sphere2->SetRadius(0.5);
$sphere2->SetCenter(1,0,0);
$sphere3 = Graphics::VTK::SphereSource->new;
$sphere3->SetThetaResolution(80);
$sphere3->SetPhiResolution(40);
$sphere3->SetRadius(0.5);
$sphere3->SetCenter(-1,0,0);
$sphere4 = Graphics::VTK::SphereSource->new;
$sphere4->SetThetaResolution(80);
$sphere4->SetPhiResolution(40);
$sphere4->SetRadius(0.5);
$sphere4->SetCenter(0,1,0);
$sphere5 = Graphics::VTK::SphereSource->new;
$sphere5->SetThetaResolution(80);
$sphere5->SetPhiResolution(40);
$sphere5->SetRadius(0.5);
$sphere5->SetCenter(0,-1,0);
$appendData = Graphics::VTK::AppendPolyData->new;
$appendData->AddInput($sphere->GetOutput);
$appendData->AddInput($sphere2->GetOutput);
$appendData->AddInput($sphere3->GetOutput);
$appendData->AddInput($sphere4->GetOutput);
$appendData->AddInput($sphere5->GetOutput);

# The dephSort object is set up to generate scalars representing
# the sort depth.  A camera is assigned for the sorting. The camera
# define the sort vector (position and focal point).
$camera = Graphics::VTK::Camera->new;
$depthSort = Graphics::VTK::DepthSortPolyData->new;
$depthSort->SetInput($appendData->GetOutput);
$depthSort->SetDirectionToBackToFront;
$depthSort->SetVector(1,1,1);
$depthSort->SetCamera($camera);
$depthSort->SortScalarsOn;
$depthSort->Update;

$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($depthSort->GetOutput);
$mapper->SetScalarRange(0,$depthSort->GetOutput->GetNumberOfCells);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$actor->GetProperty->SetOpacity(0.5);
$actor->GetProperty->SetColor(1,0,0);
$actor->RotateX(-72);

# If an Prop3D is supplied, then its transformation matrix is taken
# into account during sorting.
$depthSort->SetProp3D($actor);

# Create the RenderWindow, Renderer and both Actors

$ren1 = Graphics::VTK::Renderer->new;
$ren1->SetActiveCamera($camera);
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($actor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(300,200);

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->ResetCamera;
$ren1->GetActiveCamera->Zoom(2.2);
$renWin->Render;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;

Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
