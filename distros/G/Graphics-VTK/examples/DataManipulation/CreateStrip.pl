#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This script shows how to manually create a vtkPolyData with a
# triangle strip.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# First we'll create some points.

$points = Graphics::VTK::Points->new;
$points->InsertPoint(0,0.0,0.0,0.0);
$points->InsertPoint(1,0.0,1.0,0.0);
$points->InsertPoint(2,1.0,0.0,0.0);
$points->InsertPoint(3,1.0,1.0,0.0);
$points->InsertPoint(4,2.0,0.0,0.0);
$points->InsertPoint(5,2.0,1.0,0.0);
$points->InsertPoint(6,3.0,0.0,0.0);
$points->InsertPoint(7,3.0,1.0,0.0);

# The cell array can be thought of as a connectivity list.
# Here we specify the number of points followed by that number of
# point ids. This can be repeated as many times as there are
# primitives in the list.

$strips = Graphics::VTK::CellArray->new;
$strips->InsertNextCell(8);
#number of points
$strips->InsertCellPoint(0);
$strips->InsertCellPoint(1);
$strips->InsertCellPoint(2);
$strips->InsertCellPoint(3);
$strips->InsertCellPoint(4);
$strips->InsertCellPoint(5);
$strips->InsertCellPoint(6);
$strips->InsertCellPoint(7);
$profile = Graphics::VTK::PolyData->new;
$profile->SetPoints($points);
$profile->SetStrips($strips);

$map = Graphics::VTK::PolyDataMapper->new;
$map->SetInput($profile);

$strip = Graphics::VTK::Actor->new;
$strip->SetMapper($map);
$strip->GetProperty->SetColor(0.3800,0.7000,0.1600);

# Create the usual rendering stuff.
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($strip);

$ren1->SetBackground(1,1,1);
$renWin->SetSize(250,250);
$renWin->Render;

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# prevent the tk window from showing up then start the event loop
$MW->withdraw;



Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
