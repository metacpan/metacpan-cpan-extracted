#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of vtkSTLReader to load data into VTK from
# a file.  This example also uses vtkLODActor which changes its graphical
# representation of the data to maintain interactive performance.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Create the reader and read a data file.  Connect the mapper and actor.
$sr = Graphics::VTK::STLReader->new;
$sr->SetFileName("$VTK_DATA_ROOT/Data/42400-IDGH.stl");

$stlMapper = Graphics::VTK::PolyDataMapper->new;
$stlMapper->SetInput($sr->GetOutput);

$stlActor = Graphics::VTK::LODActor->new;
$stlActor->SetMapper($stlMapper);

# Create the Renderer, RenderWindow, and RenderWindowInteractor

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the render; set the background and size

$ren1->AddActor($stlActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);

# Zoom in closer
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.4);

# Set the user method (bound to key 'u')
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;

# Withdraw the default tk window
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
