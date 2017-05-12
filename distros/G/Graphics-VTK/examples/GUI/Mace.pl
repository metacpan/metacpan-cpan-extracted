#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;


# This example creates a polygonal model of a mace made of a sphere
# and a set of cones adjusted on its surface using glyphing. 

# The sphere is rendered to the screen through the usual VTK render window
# and interactions is performed using vtkRenderWindowInteractor.
# The basic setup of source -> mapper -> actor -> renderer ->
# renderwindow is typical of most VTK programs.  



# First we include the VTK Tcl packages which will make available 
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;


# Next we create an instance of vtkSphereSource and set some of its 
# properties

$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetThetaResolution(8);
$sphere->SetPhiResolution(8);


# We create an instance of vtkPolyDataMapper to map the polygonal data 
# into graphics primitives. We connect the output of the sphere source
# to the input of this mapper 

$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);


# Create an actor to represent the sphere. The actor coordinates rendering of
# the graphics primitives for a mapper. We set this actor's mapper to be
# the mapper which we created above.

$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);


# Next we create an instance of vtkConeSource that will be used to
# set the glyphs on the sphere's surface

$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(6);


# Glyphing is a visualization technique that represents data by using
# symbol or glyphs. In VTK, the vtkGlyph3D class allows you to create
# glyphs that can be scaled, colored and oriented along a
# direction. The glyphs (here, cones) are copied at each point of the
# input dataset (the sphere's vertices).

# Create a vtkGlyph3D to dispatch the glyph/cone geometry (SetSource) on the
# sphere dataset (SetInput). Each glyph is oriented through the dataset 
# normals (SetVectorModeToUseNormal). The resulting dataset is a set
# of cones lying on a sphere surface.

$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($sphere->GetOutput);
$glyph->SetSource($cone->GetOutput);
$glyph->SetVectorModeToUseNormal;
$glyph->SetScaleModeToScaleByVector;
$glyph->SetScaleFactor(0.25);


# We create an instance of vtkPolyDataMapper to map the polygonal data 
# into graphics primitives. We connect the output of the glyph3d
# to the input of this mapper 

$spikeMapper = Graphics::VTK::PolyDataMapper->new;
$spikeMapper->SetInput($glyph->GetOutput);


# Create an actor to represent the glyphs. The actor coordinates rendering of
# the graphics primitives for a mapper. We set this actor's mapper to be
# the mapper which we created above.

$spikeActor = Graphics::VTK::Actor->new;
$spikeActor->SetMapper($spikeMapper);


# Create the Renderer and assign actors to it. A renderer is like a
# viewport. It is part or all of a window on the screen and it is responsible
# for drawing the actors it has. We also set the background color here.

$renderer = Graphics::VTK::Renderer->new;
$renderer->AddActor($sphereActor);
$renderer->AddActor($spikeActor);
$renderer->SetBackground(1,1,1);


# We create the render window which will show up on the screen
# We put our renderer into the render window using AddRenderer. We also
# set the size to be 300 pixels by 300

$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($renderer);
$renWin->SetSize(300,300);


# Finally we create the render window interactor handling user
# interactions. vtkRenderWindowInteractor provides a
# platform-independent interaction mechanism for mouse/key/time
# events. vtkRenderWindowInteractor also provides controls for
# picking, rendering frame rate, and headlights. It is associated
# to a render window.

$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);


# vtkRenderWindowInteractor provides default key bindings.  The 'u'
# key will trigger its "user method", provided that it has been
# defined. Similarly the 'e' or 'q' key will trigger its "exit
# method". The lines below set these methods through the AddObserver
# method with the events "UserEvent" and "ExitEvent". The corresponding 
# "user-method" Tcl code will bring up the .vtkInteract widget and 
# allow the user to evaluate any Tcl code and get access to all 
# previously-created VTK objects. The
# "exit-method" Tcl code will exit (do not try to free up any objects
# we created using 'vtkCommand DeleteAllObjects' because you are right
# inside a VTK object.

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->AddObserver('ExitEvent',
 sub
  {
   exit();
  }
);


# Render the image

$renWin->Render;


# Hide the default . widget

$MW->withdraw;


# You only need this line if you run this script from a Tcl shell
# (tclsh) instead of a Tk shell (wish) 

#tkwait window .
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
