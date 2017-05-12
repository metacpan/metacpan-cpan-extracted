#!/usr/local/bin/perl -w
#
use Graphics::VTK;


# This example demonstrates how to add observers to an applicaiton. It
# extends the Step1/Tcl/Cone.tcl example by adding an oberver. See Step1 for
# more information on the basics of the pipeline


# First we include the VTK Tcl packages which will make available 
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};


# Here we define our callback

#
sub myCallback
{
 print("Starting to render");
}


# Next we create the pipelinne

$cone = Graphics::VTK::ConeSource->new;
$cone->SetHeight(3.0);
$cone->SetRadius(1.0);
$cone->SetResolution(10);

$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($cone->GetOutput);
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);

$ren1 = Graphics::VTK::Renderer->new;
$ren1->AddActor($coneActor);
$ren1->SetBackground(0.1,0.2,0.4);

# here we setup the callback
$ren1->AddObserver('StartEvent',
 sub
  {
   myCallback();
  }
);

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



