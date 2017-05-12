#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create room profile
$points = Graphics::VTK::Points->new;
$points->InsertPoint(0,1,0,0);
$points->InsertPoint(1,0,0,0);
$points->InsertPoint(2,0,10,0);
$points->InsertPoint(3,12,10,0);
$points->InsertPoint(4,12,0,0);
$points->InsertPoint(5,3,0,0);
$lines = Graphics::VTK::CellArray->new;
$lines->InsertNextCell(6);
#number of points
$lines->InsertCellPoint(0);
$lines->InsertCellPoint(1);
$lines->InsertCellPoint(2);
$lines->InsertCellPoint(3);
$lines->InsertCellPoint(4);
$lines->InsertCellPoint(5);
$profile = Graphics::VTK::PolyData->new;
$profile->SetPoints($points);
$profile->SetLines($lines);
# extrude profile to make wall
$extrude = Graphics::VTK::LinearExtrusionFilter->new;
$extrude->SetInput($profile);
$extrude->SetScaleFactor(8);
$extrude->SetVector(0,0,1);
$extrude->CappingOff;
$map = Graphics::VTK::PolyDataMapper->new;
$map->SetInput($extrude->GetOutput);
$wall = Graphics::VTK::Actor->new;
$wall->SetMapper($map);
$wall->GetProperty->SetColor(0.3800,0.7000,0.1600);
#[wall GetProperty] BackfaceCullingOff
#[wall GetProperty] FrontfaceCullingOn
# Add the actors to the renderer, set the background and size
$ren1->AddActor($wall);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->GetActiveCamera->SetViewUp(-0.181457,0.289647,0.939776);
$ren1->GetActiveCamera->SetPosition(23.3125,-28.2001,17.5756);
$ren1->GetActiveCamera->SetFocalPoint(6,5,4);
$ren1->GetActiveCamera->SetViewAngle(30);
$ren1->GetActiveCamera->ComputeViewPlaneNormal;
$ren1->ResetCameraClippingRange;
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#renWin SetFileName walls.tcl.ppm
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
