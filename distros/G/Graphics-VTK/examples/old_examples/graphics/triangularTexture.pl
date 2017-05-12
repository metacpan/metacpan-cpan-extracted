#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# create a triangular texture and save it as a ppm
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$aTriangularTexture = Graphics::VTK::TriangularTexture->new;
$aTriangularTexture->SetTexturePattern(1);
$aTriangularTexture->SetXSize(32);
$aTriangularTexture->SetYSize(32);
$points = Graphics::VTK::Points->new;
$points->InsertPoint(0,0.0,0.0,0.0);
$points->InsertPoint(1,1.0,0.0,0.0);
$points->InsertPoint(2,'.5',1.0,0.0);
$points->InsertPoint(3,1.0,0.0,0.0);
$points->InsertPoint(4,0.0,0.0,0.0);
$points->InsertPoint(5,'.5',-1.0,'.5');
$tCoords = Graphics::VTK::TCoords->new;
$tCoords->InsertTCoord(0,0.0,0.0,0.0);
$tCoords->InsertTCoord(1,1.0,0.0,0.0);
$tCoords->InsertTCoord(2,'.5','.86602540378443864676',0.0);
$tCoords->InsertTCoord(3,0.0,0.0,0.0);
$tCoords->InsertTCoord(4,1.0,0.0,0.0);
$tCoords->InsertTCoord(5,'.5','.86602540378443864676',0.0);
$pointData = Graphics::VTK::PointData->new;
$pointData->SetTCoords($tCoords);
$triangles = Graphics::VTK::CellArray->new;
$triangles->InsertNextCell(3);
$triangles->InsertCellPoint(0);
$triangles->InsertCellPoint(1);
$triangles->InsertCellPoint(2);
$triangles->InsertNextCell(3);
$triangles->InsertCellPoint(3);
$triangles->InsertCellPoint(4);
$triangles->InsertCellPoint(5);
$triangle = Graphics::VTK::PolyData->new;
$triangle->SetPolys($triangles);
$triangle->SetPoints($points);
$triangle->GetPointData->SetTCoords($tCoords);
$triangleMapper = Graphics::VTK::PolyDataMapper->new;
$triangleMapper->SetInput($triangle);
$aTexture = Graphics::VTK::Texture->new;
$aTexture->SetInput($aTriangularTexture->GetOutput);
$triangleActor = Graphics::VTK::Actor->new;
$triangleActor->SetMapper($triangleMapper);
$triangleActor->SetTexture($aTexture);
$ren1->SetBackground('.3','.7','.2');
$ren1->AddActor($triangleActor);
$ren1->GetActiveCamera->Zoom(1.5);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName("triangularTexture.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
