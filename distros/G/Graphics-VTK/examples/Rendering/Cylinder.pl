#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;


# This simple example shows how to do basic rendering and pipeline
# creation.

# We start off by loading some Tcl modules. One is the basic VTK library
# the second is a package for rendering, and the last includes a set
# of color definitions.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;

# This creates a polygonal cylinder model with eight circumferential facets.

$cylinder = Graphics::VTK::CylinderSource->new;
$cylinder->SetResolution(8);

# The mapper is responsible for pushing the geometry into the graphics
# library. It may also do color mapping, if scalars or other attributes
# are defined.

$cylinderMapper = Graphics::VTK::PolyDataMapper->new;
$cylinderMapper->SetInput($cylinder->GetOutput);

# The actor is a grouping mechanism: besides the geometry (mapper), it
# also has a property, transformation matrix, and/or texture map.
# Here we set its color and rotate it -22.5 degrees.
$cylinderActor = Graphics::VTK::Actor->new;
$cylinderActor->SetMapper($cylinderMapper);
$cylinderActor->GetProperty->SetColor(@Graphics::VTK::Colors::tomato);
$cylinderActor->RotateX(30.0);
$cylinderActor->RotateY(-45.0);

# Create the graphics structure. The renderer renders into the 
# render window. The render window interactor captures mouse events
# and will perform appropriate camera or actor manipulation
# depending on the nature of the events.

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($cylinderActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(200,200);

# The next line associates a Tcl proc with a "keypress-u" event
# in the rendering window. In this case the proc deiconifies the
# .vtkInteract Tk form that was defined when we loaded
# "package require vtkinteraction".
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# This starts the event loop and as a side effect causes an initial render.
$iren->Initialize;

# We'll zoom in a little by accessing the camera and invoking a "Zoom"
# method on it.
$ren1->GetActiveCamera->Zoom(1.5);
$renWin->Render;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;



Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
