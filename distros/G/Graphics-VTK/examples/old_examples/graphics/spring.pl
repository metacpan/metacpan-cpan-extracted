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
# create spring profile (a circle)
$points = Graphics::VTK::Points->new;
$points->InsertPoint(0,1.0,0.0,0.0);
$points->InsertPoint(1,1.0732,0.0,-0.1768);
$points->InsertPoint(2,1.25,0.0,-0.25);
$points->InsertPoint(3,1.4268,0.0,-0.1768);
$points->InsertPoint(4,1.5,0.0,0.00);
$points->InsertPoint(5,1.4268,0.0,0.1768);
$points->InsertPoint(6,1.25,0.0,0.25);
$points->InsertPoint(7,1.0732,0.0,0.1768);
$poly = Graphics::VTK::CellArray->new;
$poly->InsertNextCell(8);
#number of points
$poly->InsertCellPoint(0);
$poly->InsertCellPoint(1);
$poly->InsertCellPoint(2);
$poly->InsertCellPoint(3);
$poly->InsertCellPoint(4);
$poly->InsertCellPoint(5);
$poly->InsertCellPoint(6);
$poly->InsertCellPoint(7);
$profile = Graphics::VTK::PolyData->new;
$profile->SetPoints($points);
$profile->SetPolys($poly);
# extrude profile to make spring
$extrude = Graphics::VTK::RotationalExtrusionFilter->new;
$extrude->SetInput($profile);
$extrude->SetResolution(360);
$extrude->SetTranslation(6);
$extrude->SetDeltaRadius(1.0);
$extrude->SetAngle(2160.0);
#six revolutions
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($extrude->GetOutput);
$normals->SetFeatureAngle(60);
$map = Graphics::VTK::PolyDataMapper->new;
$map->SetInput($normals->GetOutput);
$spring = Graphics::VTK::Actor->new;
$spring->SetMapper($map);
$spring->GetProperty->SetColor(0.6902,0.7686,0.8706);
$spring->GetProperty->SetDiffuse(0.7);
$spring->GetProperty->SetSpecular(0.4);
$spring->GetProperty->SetSpecularPower(20);
$spring->GetProperty->BackfaceCullingOn;
# Add the actors to the renderer, set the background and size
$ren1->AddActor($spring);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$cam1 = $ren1->GetActiveCamera;
$cam1->Azimuth(90);
$renWin->Render;
#renWin SetFileName "spring.tcl.ppm"
#renWin SaveImageAsPPM
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
