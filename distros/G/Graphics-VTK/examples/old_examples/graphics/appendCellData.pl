#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Append datasets
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow etc.
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
# create a 1*2 cell grid
$points2 = Graphics::VTK::Points->new;
$points2->InsertNextPoint(1,1,0);
$points2->InsertNextPoint(2,1,0);
$points2->InsertNextPoint(1,0,0);
$points2->InsertNextPoint(2,0,0);
$points2->InsertNextPoint(1,-1,0);
$points2->InsertNextPoint(2,-1,0);
$faceColors2 = Graphics::VTK::Scalars->new;
$faceColors2->InsertNextScalar(2);
$faceColors2->InsertNextScalar(0);
$sgrid2 = Graphics::VTK::StructuredGrid->new;
$sgrid2->SetDimensions(2,3,1);
$sgrid2->SetPoints($points2);
$sgrid2->GetCellData->SetScalars($faceColors2);
$Append = Graphics::VTK::AppendFilter->new;
$Append->AddInput($sgrid);
$Append->AddInput($sgrid2);
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($Append->GetOutput);
$mapper->SetScalarModeToUseCellData;
$mapper->SetScalarRange(0,2);
$Checker = Graphics::VTK::Actor->new;
$Checker->SetMapper($mapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($Checker);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(255,255);
# render the image
$renWin->Render;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName('appendCellData.tcl.ppm');
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
