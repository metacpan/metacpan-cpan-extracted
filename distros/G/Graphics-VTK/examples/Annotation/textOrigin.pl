#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of vtkVectorText and vtkFollower.
# vtkVectorText is used to create 3D annotation.  vtkFollower is used to
# position the 3D text and to ensure that the text always faces the
# renderer's active camera (i.e., the text is always readable).


# First we include the VTK Tcl packages which will make available
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Create the axes and the associated mapper and actor.
$axes = Graphics::VTK::Axes->new;
$axes->SetOrigin(0,0,0);
$axesMapper = Graphics::VTK::PolyDataMapper->new;
$axesMapper->SetInput($axes->GetOutput);
$axesActor = Graphics::VTK::Actor->new;
$axesActor->SetMapper($axesMapper);

# Create the 3D text and the associated mapper and follower (a type of
# actor).  Position the text so it is displayed over the origin of the axes.
$atext = Graphics::VTK::VectorText->new;
$atext->SetText("Origin");
$textMapper = Graphics::VTK::PolyDataMapper->new;
$textMapper->SetInput($atext->GetOutput);
$textActor = Graphics::VTK::Follower->new;
$textActor->SetMapper($textMapper);
$textActor->SetScale(0.2,0.2,0.2);
$textActor->AddPosition(0,-0.1,0);

# Create the Renderer, RenderWindow, and RenderWindowInteractor.
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer.
$ren1->AddActor($axesActor);
$ren1->AddActor($textActor);

# Zoom in closer.
$ren1->GetActiveCamera->Zoom(1.6);

# Reset the clipping range of the camera; set the camera of the follower
# render.
$ren1->ResetCameraClippingRange;
$textActor->SetCamera($ren1->GetActiveCamera);
$renWin->Render;

# Set the user method (bound to key 'u')

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# Withdraw the default tk window.
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
