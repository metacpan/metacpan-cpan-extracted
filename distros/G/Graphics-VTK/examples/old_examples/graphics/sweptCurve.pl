#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
## Test the rotational extrusion filter and tube generator. Sweep a spiral
## curve to generate a tube.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create bottle profile
# draw the arrows
$points = Graphics::VTK::Points->new;
$points->InsertNextPoint(1,0,0);
$points->InsertNextPoint(0.707,0.707,1);
$points->InsertNextPoint(0,1,2);
$points->InsertNextPoint(-0.707,0.707,3);
$points->InsertNextPoint(-1,0,4);
$points->InsertNextPoint(-0.707,-0.707,5);
$points->InsertNextPoint(0,-1,6);
$points->InsertNextPoint(0.707,-0.707,7);
$lines = Graphics::VTK::CellArray->new;
$lines->InsertNextCell(8);
$lines->InsertCellPoint(0);
$lines->InsertCellPoint(1);
$lines->InsertCellPoint(2);
$lines->InsertCellPoint(3);
$lines->InsertCellPoint(4);
$lines->InsertCellPoint(5);
$lines->InsertCellPoint(6);
$lines->InsertCellPoint(7);
$profile = Graphics::VTK::PolyData->new;
$profile->SetPoints($points);
$profile->SetLines($lines);
#create the tunnel
$extrude = Graphics::VTK::RotationalExtrusionFilter->new;
$extrude->SetInput($profile);
$extrude->SetAngle(360);
$extrude->SetResolution(80);
$clean = Graphics::VTK::CleanPolyData->new;
#get rid of seam
$clean->SetInput($extrude->GetOutput);
$clean->SetTolerance(0.001);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($clean->GetOutput);
$normals->SetFeatureAngle(90);
$map = Graphics::VTK::PolyDataMapper->new;
$map->SetInput($normals->GetOutput);
$sweep = Graphics::VTK::Actor->new;
$sweep->SetMapper($map);
$sweep->GetProperty->SetColor(0.3800,0.7000,0.1600);
#create the seam
$tuber = Graphics::VTK::TubeFilter->new;
$tuber->SetInput($profile);
$tuber->SetNumberOfSides(6);
$tuber->SetRadius(0.1);
$tubeMapper = Graphics::VTK::PolyDataMapper->new;
$tubeMapper->SetInput($tuber->GetOutput);
$seam = Graphics::VTK::Actor->new;
$seam->SetMapper($tubeMapper);
$seam->GetProperty->SetColor(1.0000,0.3882,0.2784);
# Create graphics stuff
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($sweep);
$ren1->AddActor($seam);
$ren1->SetBackground(1,1,1);
$ren1->TwoSidedLightingOn;
$acam = Graphics::VTK::Camera->new;
$acam->SetClippingRange(1.38669,69.3345);
$acam->SetFocalPoint(-0.0368406,0.191581,3.37003);
$acam->SetPosition(13.6548,2.10315,2.28369);
$acam->SetViewAngle(30);
$acam->SetViewPlaneNormal(0.98735,0.13785,-0.0783399);
$acam->SetViewUp(0.157669,-0.801427,0.576936);
$ren1->SetActiveCamera($acam);
$renWin->SetSize(400,400);
$renWin->Render;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("sweptCurve.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
