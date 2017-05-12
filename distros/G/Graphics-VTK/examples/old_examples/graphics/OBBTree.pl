#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$reader = Graphics::VTK::STLReader->new;
$reader->SetFileName("$VTK_DATA/42400-IDGH.stl");
$dataMapper = Graphics::VTK::PolyDataMapper->new;
$dataMapper->SetInput($reader->GetOutput);
$model = Graphics::VTK::Actor->new;
$model->SetMapper($dataMapper);
$model->GetProperty->SetColor(1,0,0);
$obb = Graphics::VTK::OBBTree->new;
$obb->SetMaxLevel(4);
$obb->SetNumberOfCellsPerBucket(4);
$boxes = Graphics::VTK::SpatialRepresentationFilter->new;
$boxes->SetInput($reader->GetOutput);
$boxes->SetSpatialRepresentation($obb);
$boxMapper = Graphics::VTK::PolyDataMapper->new;
$boxMapper->SetInput($boxes->GetOutput);
$boxActor = Graphics::VTK::Actor->new;
$boxActor->SetMapper($boxMapper);
$boxActor->GetProperty->SetAmbient(1);
$boxActor->GetProperty->SetDiffuse(0);
$boxActor->GetProperty->SetRepresentationToWireframe;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($model);
$ren1->AddActor($boxActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);
$ren1->GetActiveCamera->Zoom(1.5);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName OBBTree.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
