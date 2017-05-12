#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of the contour filter, and the use of
# the vtkSampleFunction to generate a volume of data samples from an
# implicit function.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands from Tcl. The vtkinteraction package defines
# a simple Tcl/Tk interactor widget.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# VTK supports implicit functions of the form f(x,y,z)=constant. These 
# functions can represent things spheres, cones, etc. Here we use a 
# general form for a quadric to create an elliptical data field.
$quadric = Graphics::VTK::Quadric->new;
$quadric->SetCoefficients('.5',1,'.2',0,'.1',0,0,'.2',0,0);

# vtkSampleFunction samples an implicit function over the x-y-z range
# specified (here it defaults to -1,1 in the x,y,z directions).
$sample = Graphics::VTK::SampleFunction->new;
$sample->SetSampleDimensions(30,30,30);
$sample->SetImplicitFunction($quadric);

# Create five surfaces F(x,y,z) = constant between range specified. The
# GenerateValues() method creates n isocontour values between the range
# specified.
$contours = Graphics::VTK::ContourFilter->new;
$contours->SetInput($sample->GetOutput);
$contours->GenerateValues(5,0.0,1.2);

$contMapper = Graphics::VTK::PolyDataMapper->new;
$contMapper->SetInput($contours->GetOutput);
$contMapper->SetScalarRange(0.0,1.2);

$contActor = Graphics::VTK::Actor->new;
$contActor->SetMapper($contMapper);

# We'll put a simple outline around the data.
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($sample->GetOutput);

$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);

$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);

# The usual rendering stuff.
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

$ren1->SetBackground(1,1,1);
$ren1->AddActor($contActor);
$ren1->AddActor($outlineActor);

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;

$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
