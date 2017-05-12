#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example shows how to use cutting (vtkCutter) and how it compares
# with extracting a plane from a computational grid.


$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Read some data.
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA_ROOT/Data/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA_ROOT/Data/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;

# The cutter uses an implicit function to perform the cutting.
# Here we define a plane, specifying its center and normal.
# Then we assign the plane to the cutter.
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin($pl3d->GetOutput->GetCenter);
$plane->SetNormal(-0.287,0,0.9579);
$planeCut = Graphics::VTK::Cutter->new;
$planeCut->SetInput($pl3d->GetOutput);
$planeCut->SetCutFunction($plane);
$cutMapper = Graphics::VTK::PolyDataMapper->new;
$cutMapper->SetInput($planeCut->GetOutput);
$cutMapper->SetScalarRange($pl3d->GetOutput->GetPointData->GetScalars->GetRange);
$cutActor = Graphics::VTK::Actor->new;
$cutActor->SetMapper($cutMapper);

# Here we extract a computational plane from the structured grid.
# We render it as wireframe.
$compPlane = Graphics::VTK::StructuredGridGeometryFilter->new;
$compPlane->SetInput($pl3d->GetOutput);
$compPlane->SetExtent(0,100,0,100,9,9);
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($compPlane->GetOutput);
$planeMapper->ScalarVisibilityOff;
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$planeActor->GetProperty->SetRepresentationToWireframe;
$planeActor->GetProperty->SetColor(0,0,0);

# The outline of the data puts the data in context.
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(0,0,0);

# Create the RenderWindow, Renderer and both Actors

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($outlineActor);
$ren1->AddActor($planeActor);
$ren1->AddActor($cutActor);

$ren1->SetBackground(1,1,1);
$renWin->SetSize(400,300);

$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(11.1034,59.5328);
$cam1->SetFocalPoint(9.71821,0.458166,29.3999);
$cam1->SetPosition(-2.95748,-26.7271,44.5309);
$cam1->SetViewUp(0.0184785,0.479657,0.877262);
$iren->Initialize;

# render the image

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
