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
# lines make a nice test
$line1 = Graphics::VTK::LineSource->new;
$line1->SetPoint1(0,0,0);
$line1->SetPoint2(1,0,0);
$line1->SetResolution(1000);
$line2 = Graphics::VTK::LineSource->new;
$line2->SetPoint1(0,0,0);
$line2->SetPoint2(1,1,1);
$line2->SetResolution(1000);
#vtkAppendPolyData asource
#  asource AddInput [line1 GetOutput]
#  asource AddInput [line2 GetOutput]
$asource = Graphics::VTK::STLReader->new;
$asource->SetFileName("$VTK_DATA/42400-IDGH.stl");
#vtkCyberReader asource
#  asource SetFileName "$VTK_DATA/fran_cut"
$dataMapper = Graphics::VTK::PolyDataMapper->new;
$dataMapper->SetInput($asource->GetOutput);
$model = Graphics::VTK::Actor->new;
$model->SetMapper($dataMapper);
$model->GetProperty->SetColor(1,0,0);
#  model VisibilityOff
#vtkPointLocator locator
#vtkOBBTree locator
$locator = Graphics::VTK::CellLocator->new;
$locator->SetMaxLevel(4);
$locator->AutomaticOff;
$boxes = Graphics::VTK::SpatialRepresentationFilter->new;
$boxes->SetInput($asource->GetOutput);
$boxes->SetSpatialRepresentation($locator);
$boxMapper = Graphics::VTK::PolyDataMapper->new;
$boxMapper->SetInput($boxes->GetOutput);
#  boxMapper SetInput [boxes GetOutput 2]
$boxActor = Graphics::VTK::Actor->new;
$boxActor->SetMapper($boxMapper);
$boxActor->GetProperty->SetDiffuse(0);
$boxActor->GetProperty->SetAmbient(1);
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
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(1.4);
$renWin->Render;
#renWin SetFileName valid/SpatialRep.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
