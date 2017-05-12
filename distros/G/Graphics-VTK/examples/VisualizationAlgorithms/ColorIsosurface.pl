#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example shows how to color an isosurface with other data. Basically
# an isosurface is generated, and a data array is selected and used by the
# mapper to color the surface.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Read some data. The important thing here is to read a function as a data
# array as well as the scalar and vector.  (here function 153 is named
# "Velocity Magnitude").Later this data array will be used to color the
# isosurface.  

$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA_ROOT/Data/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA_ROOT/Data/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->AddFunction(153);
$pl3d->Update;
$pl3d->DebugOn;

# The contoru filter uses the labeled scalar (function number 100
# above to generate the contour surface; all other data is interpolated
# during the contouring process.

$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($pl3d->GetOutput);
$iso->SetValue(0,'.24');

$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($iso->GetOutput);
$normals->SetFeatureAngle(45);

# We indicate to the mapper to use the velcoity magnitude, which is a 
# vtkDataArray that makes up part of the point attribute data.

$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($normals->GetOutput);
$isoMapper->ScalarVisibilityOn;
$isoMapper->SetScalarRange(0,1500);
$isoMapper->SetScalarModeToUsePointFieldData;
$isoMapper->ColorByArrayComponent("Velocity Magnitude",0);

$isoActor = Graphics::VTK::LODActor->new;
$isoActor->SetMapper($isoMapper);
$isoActor->SetNumberOfCloudPoints(1000);

$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);

# Create the usual rendering stuff.

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->SetBackground(0.1,0.2,0.4);

$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(9.71821,0.458166,29.3999);
$cam1->SetPosition(2.7439,-37.3196,38.7167);
$cam1->SetViewUp(-0.16123,0.264271,0.950876);

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
