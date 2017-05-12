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
$points = Graphics::VTK::Points->new;
$points->InsertNextPoint(0,0,0);
$points->InsertNextPoint(0,0,4);
$points->InsertNextPoint(3,-2,1);
$points->InsertNextPoint(3,2,1);
$points->InsertNextPoint(-3,2,1);
$points->InsertNextPoint(-3,-2,1);
$points->InsertNextPoint(0,-3,-2);
$points->InsertNextPoint(0,3,-2);
$points->InsertNextPoint(2,0,-4);
$points->InsertNextPoint(-2,0,-4);
$points->InsertNextPoint(0,-2,2);
$points->InsertNextPoint(0,2,2);
$faces = Graphics::VTK::CellArray->new;
$faces->InsertNextCell(3);
$faces->InsertCellPoint(1);
$faces->InsertCellPoint(0);
$faces->InsertCellPoint(2);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(1);
$faces->InsertCellPoint(2);
$faces->InsertCellPoint(3);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(1);
$faces->InsertCellPoint(3);
$faces->InsertCellPoint(11);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(11);
$faces->InsertCellPoint(3);
$faces->InsertCellPoint(0);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(1);
$faces->InsertCellPoint(0);
$faces->InsertCellPoint(4);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(1);
$faces->InsertCellPoint(4);
$faces->InsertCellPoint(5);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(1);
$faces->InsertCellPoint(5);
$faces->InsertCellPoint(10);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(10);
$faces->InsertCellPoint(5);
$faces->InsertCellPoint(0);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(2);
$faces->InsertCellPoint(0);
$faces->InsertCellPoint(6);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(6);
$faces->InsertCellPoint(0);
$faces->InsertCellPoint(5);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(7);
$faces->InsertCellPoint(0);
$faces->InsertCellPoint(3);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(4);
$faces->InsertCellPoint(0);
$faces->InsertCellPoint(7);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(6);
$faces->InsertCellPoint(9);
$faces->InsertCellPoint(8);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(6);
$faces->InsertCellPoint(8);
$faces->InsertCellPoint(2);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(2);
$faces->InsertCellPoint(8);
$faces->InsertCellPoint(3);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(3);
$faces->InsertCellPoint(8);
$faces->InsertCellPoint(7);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(7);
$faces->InsertCellPoint(8);
$faces->InsertCellPoint(9);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(7);
$faces->InsertCellPoint(9);
$faces->InsertCellPoint(4);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(4);
$faces->InsertCellPoint(9);
$faces->InsertCellPoint(5);
$faces->InsertNextCell(3);
$faces->InsertCellPoint(5);
$faces->InsertCellPoint(9);
$faces->InsertCellPoint(6);
$model = Graphics::VTK::PolyData->new;
$model->SetPolys($faces);
$model->SetPoints($points);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
#vtkButterflySubdivisionFilter subdivide
$subdivide = Graphics::VTK::LoopSubdivisionFilter->new;
$subdivide->SetInput($model);
$subdivide->SetNumberOfSubdivisions(5);
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($subdivide->GetOutput);
$rose = Graphics::VTK::Actor->new;
$rose->SetMapper($mapper);
$fe = Graphics::VTK::FeatureEdges->new;
$fe->SetInput($subdivide->GetOutput);
$fe->SetFeatureAngle(100);
$feMapper = Graphics::VTK::PolyDataMapper->new;
$feMapper->SetInput($fe->GetOutput);
$edges = Graphics::VTK::Actor->new;
$edges->SetMapper($feMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($rose);
$ren1->AddActor($edges);
$backP = Graphics::VTK::Property->new;
$backP->SetDiffuseColor(1,1,'.3');
$rose->SetBackfaceProperty($backP);
$rose->GetProperty->SetDiffuseColor(1,'.4','.3');
$rose->GetProperty->SetSpecular('.4');
$rose->GetProperty->SetDiffuse('.8');
$rose->GetProperty->SetSpecularPower(40);
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
$renWin->SetFileName("goblet.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
