#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates how to use implicit modelling.

# first we load in the standard vtk packages into tcl
$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;

# Create lines which serve as the "seed" geometry. The lines spell the
# word "hello".

$reader = Graphics::VTK::PolyDataReader->new;
$reader->SetFileName("$VTK_DATA_ROOT/Data/hello.vtk");
$lineMapper = Graphics::VTK::PolyDataMapper->new;
$lineMapper->SetInput($reader->GetOutput);
$lineActor = Graphics::VTK::Actor->new;
$lineActor->SetMapper($lineMapper);
$lineActor->GetProperty->SetColor(@Graphics::VTK::Colors::red);

# Create implicit model with vtkImplicitModeller. This computes a scalar
# field which is the distance from the generating geometry. The contour
# filter then extracts the geoemtry at the distance value 0.25 from the
# generating geometry.

$imp = Graphics::VTK::ImplicitModeller->new;
$imp->SetInput($reader->GetOutput);
$imp->SetSampleDimensions(110,40,20);
$imp->SetMaximumDistance(0.25);
$imp->SetModelBounds(-1.0,10.0,-1.0,3.0,-1.0,1.0);
$contour = Graphics::VTK::ContourFilter->new;
$contour->SetInput($imp->GetOutput);
$contour->SetValue(0,0.25);
$impMapper = Graphics::VTK::PolyDataMapper->new;
$impMapper->SetInput($contour->GetOutput);
$impMapper->ScalarVisibilityOff;
$impActor = Graphics::VTK::Actor->new;
$impActor->SetMapper($impMapper);
$impActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$impActor->GetProperty->SetOpacity(0.5);

# Create the usual graphics stuff.
# Create the RenderWindow, Renderer and both Actors

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($lineActor);
$ren1->AddActor($impActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(600,250);

$camera = Graphics::VTK::Camera->new;
$camera->SetClippingRange(1.81325,90.6627);
$camera->SetFocalPoint(4.5,1,0);
$camera->SetPosition(4.5,1.0,6.73257);
$camera->SetViewUp(0,1,0);
$camera->Zoom(0.8);
$ren1->SetActiveCamera($camera);

$iren->Initialize;
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# prevent the tk window from showing up then start the event loop
$MW->withdraw;


Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
