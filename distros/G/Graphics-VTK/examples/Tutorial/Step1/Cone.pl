#!/usr/local/bin/perl -w
#
use Graphics::VTK;


# This example creates a polygonal model of a cone, and then rendered it to
# the screen. It willrotate the cone 360 degrees and then exit. The basic
# setup of source -> mapper -> actor -> renderer -> renderwindow is 
# typical of most VTK programs.



# First we include the VTK Tcl packages which will make available 
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};


# Next we create an instance of vtkConeSource and set some of its 
# properties

$cone = Graphics::VTK::ConeSource->new;
$cone->SetHeight(3.0);
$cone->SetRadius(1.0);
$cone->SetResolution(10);


# We create an instance of vtkPolyDataMapper to map the polygonal data 
# into graphics primitives. We connect the output of the cone souece 
# to the input of this mapper 

$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($cone->GetOutput);


# create an actor to represent the cone. The actor coordinates rendering of
# the graphics primitives for a mapper. We set this actor's mapper to be
# coneMapper which we created above.

$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);


# Create the Renderer and assign actors to it. A renderer is like a
# viewport. It is part or all of a window on the screen and it is responsible
# for drawing the actors it has.  We also set the background color here

$ren1 = Graphics::VTK::Renderer->new;
$ren1->AddActor($coneActor);
$ren1->SetBackground(0.1,0.2,0.4);


# Finally we create the render window which will show up on the screen
# We put our renderer into the render window using AddRenderer. We also
# set the size to be 300 pixels by 300

$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetSize(300,300);


# now we loop over 360 degreeees and render the cone each time

for ($i = 0; $i < 360; $i += 1)
 {
  # render the image
  $renWin->Render;
  # rotate the active camera by one degree
  $ren1->GetActiveCamera->Azimuth(1);
 }


# Free up any objects we created

#vtkCommand DeleteAllObjects


# exit the application

exit();



