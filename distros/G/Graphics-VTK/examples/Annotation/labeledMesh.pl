#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of vtkLabeledDataMapper.  This class
# is used for displaying numerical data from an underlying data set.  In
# the case of this example, the underlying data are the point and cell
# ids.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Create a selection window.  We will display the point and cell ids that
# lie within this window.
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

# Create a sphere and its associated mapper and actor.
$sphere = Graphics::VTK::SphereSource->new;
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereMapper->GlobalImmediateModeRenderingOn;
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);

# Generate data arrays containing point and cell ids
$ids = Graphics::VTK::IdFilter->new;
$ids->SetInput($sphere->GetOutput);
$ids->PointIdsOn;
$ids->CellIdsOn;
$ids->FieldDataOn;

# Create the renderer here because vtkSelectVisiblePoints needs it.
$ren1 = Graphics::VTK::Renderer->new;

# Create labels for points
$visPts = Graphics::VTK::SelectVisiblePoints->new;
$visPts->SetInput($ids->GetOutput);
$visPts->SetRenderer($ren1);
$visPts->SelectionWindowOn;
$visPts->SetSelection($xmin,$xmin + $xLength,$ymin,$ymin + $yLength);

# Create the mapper to display the point ids.  Specify the
# format to use for the labels.  Also create the associated actor.
$ldm = Graphics::VTK::LabeledDataMapper->new;
$ldm->SetInput($visPts->GetOutput);
$ldm->SetLabelFormat("%g");
$ldm->SetLabelModeToLabelFieldData;
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
# Create the mapper to display the cell ids.  Specify the
# format to use for the labels.  Also create the associated actor.
$cellMapper = Graphics::VTK::LabeledDataMapper->new;
$cellMapper->SetInput($visCells->GetOutput);
$cellMapper->SetLabelFormat("%g");
$cellMapper->SetLabelModeToLabelFieldData;
$cellLabels = Graphics::VTK::Actor2D->new;
$cellLabels->SetMapper($cellMapper);
$cellLabels->GetProperty->SetColor(0,1,0);

# Create the RenderWindow and RenderWindowInteractor

$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer; set the background and size
# render
$ren1->AddActor($sphereActor);
$ren1->AddActor2D($rectActor);
$ren1->AddActor2D($pointLabels);
$ren1->AddActor2D($cellLabels);

$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$renWin->Render;

# Set the user method (bound to key 'u')

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# Withdraw the default tk window.
$MW->withdraw;

# Create a tcl procedure to move the selection window across the data set.
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

# Create a tcl procedure to draw the selection window at each location it
# is moved to.
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
 # Call Modified because InsertPoints does not modify vtkPoints
 # (for performance reasons).
 $pts->Modified;

 $renWin->Render;
}

# Move the selection window across the data set.
MoveWindow();
# Put the selection window in the center of the render window.
# This works because the xmin = ymin = 200, xLength = yLength = 100, and
# the render window size is 500 x 500.
PlaceWindow($xmin,$ymin);
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
