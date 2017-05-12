#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates how to draw 3D polydata (in world coordinates) in
# the 2D overlay plane. Useful for selection loops, etc.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create the visualization pipeline
# create a sphere
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetThetaResolution(10);
$sphere->SetPhiResolution(20);
# extract a group of triangles and their boundary edges
$gf = Graphics::VTK::GeometryFilter->new;
$gf->SetInput($sphere->GetOutput);
$gf->CellClippingOn;
$gf->SetCellMinimum(10);
$gf->SetCellMaximum(17);
$edges = Graphics::VTK::FeatureEdges->new;
$edges->SetInput($gf->GetOutput);
# setup the mapper to draw points from world coordinate system
$worldCoordinates = Graphics::VTK::Coordinate->new;
$worldCoordinates->SetCoordinateSystemToWorld;
$mapLines = Graphics::VTK::PolyDataMapper2D->new;
$mapLines->SetInput($edges->GetOutput);
$mapLines->SetTransformCoordinate($worldCoordinates);
$linesActor = Graphics::VTK::Actor2D->new;
$linesActor->SetMapper($mapLines);
$linesActor->GetProperty->SetColor(0,1,0);
# mapper and actor
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($sphere->GetOutput);
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($mapper);
# Create graphics stuff
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($sphereActor);
$ren1->AddActor2D($linesActor);
$renWin->SetSize(250,250);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(0.294791,17.3744);
$cam1->SetFocalPoint(0,0,0);
$cam1->SetPosition(1.60648,0.00718286,-2.47173);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.634086,0.655485,-0.410213);
$cam1->Zoom(1.25);
$iren->Initialize;
$renWin->SetFileName("drawMesh.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
