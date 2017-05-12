#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example shows how to use decimation to reduce a polygonal mesh. We also
# use mesh smoothing and generate surface normals to give a pleasing result.


$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# We start by reading some data that was originally captured from
# a Cyberware laser digitizing system.

$fran = Graphics::VTK::PolyDataReader->new;
$fran->SetFileName("$VTK_DATA_ROOT/Data/fran_cut.vtk");

# We want to preserve topology (not let any cracks form). This may limit
# the total reduction possible, which we have specified at 90%.

$deci = Graphics::VTK::DecimatePro->new;
$deci->SetInput($fran->GetOutput);
$deci->SetTargetReduction(0.9);
$deci->PreserveTopologyOn;
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($fran->GetOutput);
$normals->FlipNormalsOn;
$franMapper = Graphics::VTK::PolyDataMapper->new;
$franMapper->SetInput($normals->GetOutput);
$franActor = Graphics::VTK::Actor->new;
$franActor->SetMapper($franMapper);
$franActor->GetProperty->SetColor(1.0,0.49,0.25);

# Create the RenderWindow, Renderer and both Actors

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($franActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(250,250);

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

$cam1 = Graphics::VTK::Camera->new;
$cam1->SetClippingRange(0.0475572,2.37786);
$cam1->SetFocalPoint(0.052665,-0.129454,-0.0573973);
$cam1->SetPosition(0.327637,-0.116299,-0.256418);
$cam1->SetViewUp(-0.0225386,0.999137,0.034901);
$ren1->SetActiveCamera($cam1);

$iren->Initialize;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;



Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
