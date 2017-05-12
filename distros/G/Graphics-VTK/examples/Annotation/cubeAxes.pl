#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of vtkCubeAxesActor2D to indicate the
# position in space that the camera is currently viewing.
# The vtkCubeAxesActor2D draws axes on the bounding box of the data set and
# labels the axes with x-y-z coordinates.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Create a vtkBYUReader and read in a data set.

$fohe = Graphics::VTK::BYUReader->new;
$fohe->SetGeometryFileName("$VTK_DATA_ROOT/Data/teapot.g");
# Create a vtkPolyDataNormals filter to calculate the normals of the data set.
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($fohe->GetOutput);
# Set up the associated mapper and actor.
$foheMapper = Graphics::VTK::PolyDataMapper->new;
$foheMapper->SetInput($normals->GetOutput);
$foheActor = Graphics::VTK::LODActor->new;
$foheActor->SetMapper($foheMapper);

# Create a vtkOutlineFilter to draw the bounding box of the data set.  Also
# create the associated mapper and actor.
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($normals->GetOutput);
$mapOutline = Graphics::VTK::PolyDataMapper->new;
$mapOutline->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($mapOutline);
$outlineActor->GetProperty->SetColor(0,0,0);

# Create a vtkCamera, and set the camera parameters.
$camera = Graphics::VTK::Camera->new;
$camera->SetClippingRange(1.60187,20.0842);
$camera->SetFocalPoint(0.21406,1.5,0);
$camera->SetPosition(8.3761,4.94858,4.12505);
$camera->SetViewUp(0.180325,0.549245,-0.815974);

# Create a vtkLight, and set the light parameters.
$light = Graphics::VTK::Light->new;
$light->SetFocalPoint(0.21406,1.5,0);
$light->SetPosition(8.3761,4.94858,4.12505);

# Create the Renderers.  Assign them the appropriate viewport coordinates,
# active camera, and light.
$ren1 = Graphics::VTK::Renderer->new;
$ren1->SetViewport(0,0,0.5,1.0);
$ren1->SetActiveCamera($camera);
$ren1->AddLight($light);
$ren2 = Graphics::VTK::Renderer->new;
$ren2->SetViewport(0.5,0,1.0,1.0);
$ren2->SetActiveCamera($camera);
$ren2->AddLight($light);

# Create the RenderWindow and RenderWindowInteractor.
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->AddRenderer($ren2);
$renWin->SetWindowName("VTK - Cube Axes");
$renWin->SetSize(600,300);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, and set the background.

$ren1->AddProp($foheActor);
$ren1->AddProp($outlineActor);
$ren2->AddProp($foheActor);
$ren2->AddProp($outlineActor);

$ren1->SetBackground(0.1,0.2,0.4);
$ren2->SetBackground(0.1,0.2,0.4);

# Create a vtkCubeAxesActor2D.  Use the outer edges of the bounding box to
# draw the axes.  Add the actor to the renderer.
$axes = Graphics::VTK::CubeAxesActor2D->new;
$axes->SetInput($normals->GetOutput);
$axes->SetCamera($ren1->GetActiveCamera);
$axes->SetLabelFormat("%6.4g");
$axes->ShadowOn;
$axes->SetFlyModeToOuterEdges;
$axes->SetFontFactor(0.8);
$axes->GetProperty->SetColor(1,1,1);
$ren1->AddProp($axes);

# Create a vtkCubeAxesActor2D.  Use the closest vertex to the camera to
# determine where to draw the axes.  Add the actor to the renderer.
$axes2 = Graphics::VTK::CubeAxesActor2D->new;
$axes2->SetProp($foheActor);
$axes2->SetCamera($ren2->GetActiveCamera);
$axes2->SetLabelFormat("%6.4g");
$axes2->ShadowOn;
$axes2->SetFlyModeToClosestTriad;
$axes2->SetFontFactor(0.8);
$axes2->GetProperty->SetColor(1,1,1);
$axes2->ScalingOff;
$ren2->AddProp($axes2);

# Render
$renWin->Render;

# Set the user method (bound to key 'u')

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;

# Set up a check for aborting rendering.
#
sub TkCheckAbort
{
 my $foo;
 $foo = $renWin->GetEventPending;
 $renWin->SetAbortRender(1) if ($foo != 0);
}
$renWin->AddObserver('AbortCheckEvent',
 sub
  {
   TkCheckAbort();
  }
);

# Withdraw the default tk window.
$MW->withdraw;


Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
