#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# cell scalars to point scalars
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and RenderWindowInteractor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a 2*2 cell/3*3 pt structuredgrid
$points = Graphics::VTK::Points->new;
$points->InsertNextPoint(-1,1,0);
$points->InsertNextPoint(0,1,0);
$points->InsertNextPoint(1,1,0);
$points->InsertNextPoint(-1,0,0);
$points->InsertNextPoint(0,0,0);
$points->InsertNextPoint(1,0,0);
$points->InsertNextPoint(-1,-1,0);
$points->InsertNextPoint(0,-1,0);
$points->InsertNextPoint(1,-1,0);
$faceColors = Graphics::VTK::Scalars->new;
$faceColors->InsertNextScalar(0);
$faceColors->InsertNextScalar(1);
$faceColors->InsertNextScalar(1);
$faceColors->InsertNextScalar(2);
$sgrid = Graphics::VTK::StructuredGrid->new;
$sgrid->SetDimensions(3,3,1);
$sgrid->SetPoints($points);
$sgrid->GetCellData->SetScalars($faceColors);
$Cell2Point = Graphics::VTK::CellDataToPointData->new;
$Cell2Point->SetInput($sgrid);
$Cell2Point->PassCellDataOn;
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($Cell2Point->GetStructuredGridOutput);
$mapper->SetScalarModeToUsePointData;
$mapper->SetScalarRange(0,2);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($actor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(256,256);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$MW->withdraw;
$renWin->SetFileName('CellDataToPointData.tcl.ppm');
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
