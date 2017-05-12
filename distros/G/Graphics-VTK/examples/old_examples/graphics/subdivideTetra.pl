#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# include get the vtk interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a tetrahedron
$tetraPoints = Graphics::VTK::Points->new;
$tetraPoints->SetNumberOfPoints(4);
$tetraPoints->InsertPoint(0,0,0,1.73205);
$tetraPoints->InsertPoint(1,0,1.63299,-0.57735);
$tetraPoints->InsertPoint(2,-1.41421,-0.816497,-0.57735);
$tetraPoints->InsertPoint(3,1.41421,-0.816497,-0.57735);
$aTetra = Graphics::VTK::Tetra->new;
$aTetra->GetPointIds->SetId(0,0);
$aTetra->GetPointIds->SetId(1,1);
$aTetra->GetPointIds->SetId(2,2);
$aTetra->GetPointIds->SetId(3,3);
$aTetraGrid = Graphics::VTK::UnstructuredGrid->new;
$aTetraGrid->Allocate(1,1);
$aTetraGrid->InsertNextCell($aTetra->GetCellType,$aTetra->GetPointIds);
$aTetraGrid->SetPoints($tetraPoints);
$lut = Graphics::VTK::LookupTable->new;
$lut->SetNumberOfColors(3);
$lut->Build;
$lut->SetTableValue(0,0,0,0,0);
$lut->SetTableValue(1,1,'.3','.3',1);
$lut->SetTableValue(2,'.8','.8','.9',1);
$lut->SetTableRange(0,2);
$tris = Graphics::VTK::GeometryFilter->new;
$tris->SetInput($aTetraGrid);
$loopS = Graphics::VTK::LoopSubdivisionFilter->new;
$loopS->SetInput($tris->GetOutput);
$loopS->SetNumberOfSubdivisions(4);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($loopS->GetOutput);
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($normals->GetOutput);
$mapper->SetScalarModeToUseCellData;
$mapper->SetLookupTable($lut);
$mapper->SetScalarRange(0,2);
$tetraActor = Graphics::VTK::Actor->new;
$tetraActor->SetMapper($mapper);
$tetraActor->GetProperty->SetDiffuse('.8');
$tetraActor->GetProperty->SetSpecular('.4');
$tetraActor->GetProperty->SetSpecularPower(20);
$tetraActor->GetProperty->SetDiffuseColor(1,'.6','.3');
# Add the actors to the renderer, set the background and size
$ren1->AddActor($tetraActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(300,300);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.4);
$iren->Initialize;
$renWin->SetFileName("subdivideTetra.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
