#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInteractor;
use Graphics::VTK::Tk::vtkInt;
#source $VTK_TCL/WidgetObject.tcl
# Create a line for display of the alpha
$points = Graphics::VTK::Points->new;
$alphaLine = Graphics::VTK::CellArray->new;
# Starting point.
$points->InsertNextPoint(0.0,0.0,4.0);
$points->InsertNextPoint(0.0,0.4,0.0);
$points->InsertNextPoint(0.0,10.0,0.0);
$points->InsertNextPoint(0.0,10.2,4.0);
$points->InsertNextPoint(4.0,0.0,4.0);
$points->InsertNextPoint(4.0,0.4,0.0);
$points->InsertNextPoint(4.0,10.0,0.0);
$points->InsertNextPoint(4.0,10.2,4.0);
$alphaLine->InsertNextCell(4);
$alphaLine->InsertCellPoint(0);
$alphaLine->InsertCellPoint(1);
$alphaLine->InsertCellPoint(2);
$alphaLine->InsertCellPoint(3);
$alphaLine->InsertNextCell(4);
$alphaLine->InsertCellPoint(4);
$alphaLine->InsertCellPoint(5);
$alphaLine->InsertCellPoint(6);
$alphaLine->InsertCellPoint(7);
$data = Graphics::VTK::PolyData->new;
$data->SetPoints($points);
$data->SetLines($alphaLine);
$tube = Graphics::VTK::TubeFilter->new;
$tube->SetNumberOfSides(10);
$tube->SetInput($data);
$tube->SetRadius(1.0);
$tube->CappingOn;
$mapper1 = Graphics::VTK::PolyDataMapper->new;
$mapper1->SetInput($tube->GetOutput);
$actor1 = Graphics::VTK::Actor->new;
$actor1->SetMapper($mapper1);
$bfp = Graphics::VTK::Property->new;
$actor1->SetBackfaceProperty($bfp);
$actor1->GetProperty->SetColor(1.0,0.6,0.6);
$actor1->GetBackfaceProperty->SetColor(0.0,1.0,1.0);
$actor1->GetBackfaceProperty->SetAmbient(0.5);
$actor1->GetBackfaceProperty->SetDiffuse(0.5);
$actor1->GetProperty->SetAmbient(0.5);
$actor1->GetProperty->SetDiffuse(0.5);
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->SetDesiredUpdateRate(20);
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($actor1);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(400,300);
# render the image
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.4);
$iren->Initialize;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
