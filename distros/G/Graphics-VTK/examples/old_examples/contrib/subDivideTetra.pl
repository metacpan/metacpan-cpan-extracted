#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Contour every cell type
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
$tetraPoints = Graphics::VTK::Points->new;
$tetraPoints->SetNumberOfPoints(4);
$tetraPoints->InsertPoint(0,0,0,0);
$tetraPoints->InsertPoint(1,1,0,0);
$tetraPoints->InsertPoint(2,'.5',1,0);
$tetraPoints->InsertPoint(3,'.5','.5',1);
$aTetra = Graphics::VTK::Tetra->new;
$aTetra->GetPointIds->SetId(0,0);
$aTetra->GetPointIds->SetId(1,1);
$aTetra->GetPointIds->SetId(2,2);
$aTetra->GetPointIds->SetId(3,3);
$aTetraGrid = Graphics::VTK::UnstructuredGrid->new;
$aTetraGrid->Allocate(1,1);
$aTetraGrid->InsertNextCell($aTetra->GetCellType,$aTetra->GetPointIds);
$aTetraGrid->SetPoints($tetraPoints);
$sub = Graphics::VTK::SubdivideTetra->new;
$sub->SetInput($aTetraGrid);
$shrinker = Graphics::VTK::ShrinkFilter->new;
$shrinker->SetInput($sub->GetOutput);
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($shrinker->GetOutput);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$actor->GetProperty->SetColor(@Graphics::VTK::Colors::mint);
# define graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($actor);
$ren1->SetBackground(0.1,0.2,0.4);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(0.183196,9.15979);
$cam1->SetFocalPoint(0.579471,0.462507,0.283392);
$cam1->SetPosition(-1.04453,0.345281,-0.556222);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(0.197321,0.843578,-0.499441);
$ren1->ResetCameraClippingRange;
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
