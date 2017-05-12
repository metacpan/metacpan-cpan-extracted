#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates how to extract "computational planes" from a
# structured dataset. Structured data has a natural, logical coordinate
# system based on i-j-k indices. Specifying imin,imax, jmin,jmax, kmin,kmax
# pairs can indicate a point, line, plane, or volume of data.

# In this example, we extract three planes and warp them using scalar values
# in the direction of the local normal at each point. This gives a sort of
# "velocity profile" that indicates the nature of the flow.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands from Tcl. The vtkinteraction package defines
# a simple Tcl/Tk interactor widget.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Here we read data from a annular combustor. A combustor burns fuel and air
# in a gas turbine (e.g., a jet engine) and the hot gas eventually makes its
# way to the turbine section.

$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA_ROOT/Data/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA_ROOT/Data/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;

# Planes are specified using a imin,imax, jmin,jmax, kmin,kmax coordinate
# specification. Min and max i,j,k values are clamped to 0 and maximum value.

$plane = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane->SetInput($pl3d->GetOutput);
$plane->SetExtent(10,10,1,100,1,100);
$plane2 = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane2->SetInput($pl3d->GetOutput);
$plane2->SetExtent(30,30,1,100,1,100);
$plane3 = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane3->SetInput($pl3d->GetOutput);
$plane3->SetExtent(45,45,1,100,1,100);

# We use an append filter because that way we can do the warping, etc. just
# using a single pipeline and actor.

$appendF = Graphics::VTK::AppendPolyData->new;
$appendF->AddInput($plane->GetOutput);
$appendF->AddInput($plane2->GetOutput);
$appendF->AddInput($plane3->GetOutput);
$warp = Graphics::VTK::WarpScalar->new;
$warp->SetInput($appendF->GetOutput);
$warp->UseNormalOn;
$warp->SetNormal(1.0,0.0,0.0);
$warp->SetScaleFactor(2.5);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($warp->GetPolyDataOutput);
$normals->SetFeatureAngle(60);
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($normals->GetOutput);
$planeMapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);

# The outline provides context for the data and the planes.
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);

# Create the usual graphics stuff/

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

$ren1->AddActor($outlineActor);
$ren1->AddActor($planeActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);

# Create an initial view.
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(8.88908,0.595038,29.3342);
$cam1->SetPosition(-12.3332,31.7479,41.2387);
$cam1->SetViewUp(0.060772,-0.319905,0.945498);
$iren->Initialize;

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;



Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
