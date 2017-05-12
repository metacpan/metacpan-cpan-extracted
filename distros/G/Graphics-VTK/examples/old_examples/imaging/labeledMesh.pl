#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# demonstrate use of point labeling and the selection window
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Create a selection window
$xmin = 200;
$xLength = 100;
$xmax = $xmin + $xLength;
$ymin = 200;
$yLength = 100;
$ymax = $ymin + $yLength;
$pts = Graphics::VTK::Points->new;
$pts->InsertPoint(0,$xmin,$ymin,0);
$pts->InsertPoint(1,$xmax,$ymin,0);
$pts->InsertPoint(2,$xmax,$ymax,0);
$pts->InsertPoint(3,$xmin,$ymax,0);
$rect = Graphics::VTK::CellArray->new;
$rect->InsertNextCell(5);
$rect->InsertCellPoint(0);
$rect->InsertCellPoint(1);
$rect->InsertCellPoint(2);
$rect->InsertCellPoint(3);
$rect->InsertCellPoint(0);
$selectRect = Graphics::VTK::PolyData->new;
$selectRect->SetPoints($pts);
$selectRect->SetLines($rect);
$rectMapper = Graphics::VTK::PolyDataMapper2D->new;
$rectMapper->SetInput($selectRect);
$rectActor = Graphics::VTK::Actor2D->new;
$rectActor->SetMapper($rectMapper);
# Create asphere
$sphere = Graphics::VTK::SphereSource->new;
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereMapper->GlobalImmediateModeRenderingOn;
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);
# Generate ids for labeling
$ids = Graphics::VTK::IdFilter->new;
$ids->SetInput($sphere->GetOutput);
$ids->PointIdsOn;
$ids->CellIdsOn;
$ids->FieldDataOn;
# Create labels for points
$visPts = Graphics::VTK::SelectVisiblePoints->new;
$visPts->SetInput($ids->GetOutput);
$visPts->SetRenderer($ren1);
$visPts->SelectionWindowOn;
$visPts->SetSelection($xmin,$xmin + $xLength,$ymin,$ymin + $yLength);
$ldm = Graphics::VTK::LabeledDataMapper->new;
$ldm->SetInput($visPts->GetOutput);
$ldm->SetLabelFormat("%g");
#    ldm SetLabelModeToLabelScalars
#    ldm SetLabelModeToLabelNormals
$ldm->SetLabelModeToLabelFieldData;
#    ldm SetLabeledComponent 0
$pointLabels = Graphics::VTK::Actor2D->new;
$pointLabels->SetMapper($ldm);
# Create labels for cells
$cc = Graphics::VTK::CellCenters->new;
$cc->SetInput($ids->GetOutput);
$visCells = Graphics::VTK::SelectVisiblePoints->new;
$visCells->SetInput($cc->GetOutput);
$visCells->SetRenderer($ren1);
$visCells->SelectionWindowOn;
$visCells->SetSelection($xmin,$xmin + $xLength,$ymin,$ymin + $yLength);
$cellMapper = Graphics::VTK::LabeledDataMapper->new;
$cellMapper->SetInput($visCells->GetOutput);
$cellMapper->SetLabelFormat("%g");
#    cellMapper SetLabelModeToLabelScalars
#    cellMapper SetLabelModeToLabelNormals
$cellMapper->SetLabelModeToLabelFieldData;
$cellLabels = Graphics::VTK::Actor2D->new;
$cellLabels->SetMapper($cellMapper);
$cellLabels->GetProperty->SetColor(0,1,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($sphereActor);
$ren1->AddActor2D($rectActor);
$ren1->AddActor2D($pointLabels);
$ren1->AddActor2D($cellLabels);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$renWin->Render;
#renWin SetFileName "labeledMesh.tcl.ppm"
#renWin SaveImageAsPPM
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#
sub MoveWindow
{
 my $PlaceWindow;
 my $x;
 my $y;
 for ($y = 100; $y < 300; $y += 25)
  {
   for ($x = 100; $x < 300; $x += 25)
    {
     PlaceWindow($x,$y);
    }
  }
}
#
sub PlaceWindow
{
 my $xmin = shift;
 my $ymin = shift;
 my $xmax;
 my $ymax;
 # Global Variables Declared for this function: xLength, yLength
 $xmax = $xmin + $xLength;
 $ymax = $ymin + $yLength;
 $visPts->SetSelection($xmin,$xmax,$ymin,$ymax);
 $visCells->SetSelection($xmin,$xmax,$ymin,$ymax);
 $pts->InsertPoint(0,$xmin,$ymin,0);
 $pts->InsertPoint(1,$xmax,$ymin,0);
 $pts->InsertPoint(2,$xmax,$ymax,0);
 $pts->InsertPoint(3,$xmin,$ymax,0);
 $pts->Modified;
 #because insertions don't modify object - performance reasons
 $renWin->Render;
}
MoveWindow();
PlaceWindow($xmin,$ymin);
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
