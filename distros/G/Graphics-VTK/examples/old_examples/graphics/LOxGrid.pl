#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
## LOx post CFD case study
# get helper scripts
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# read data
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/postxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/postq.bin");
$pl3d->Update;
# computational planes
$floorComp = Graphics::VTK::StructuredGridGeometryFilter->new;
$floorComp->SetExtent(0,37,0,75,0,0);
$floorComp->SetInput($pl3d->GetOutput);
$floorComp->Update;
$floorMapper = Graphics::VTK::PolyDataMapper->new;
$floorMapper->SetInput($floorComp->GetOutput);
$floorMapper->ScalarVisibilityOff;
$floorActor = Graphics::VTK::Actor->new;
$floorActor->SetMapper($floorMapper);
$floorActor->GetProperty->SetRepresentationToWireframe;
$floorActor->GetProperty->SetColor(0,0,0);
$postComp = Graphics::VTK::StructuredGridGeometryFilter->new;
$postComp->SetExtent(10,10,0,75,0,37);
$postComp->SetInput($pl3d->GetOutput);
$postMapper = Graphics::VTK::PolyDataMapper->new;
$postMapper->SetInput($postComp->GetOutput);
$postMapper->ScalarVisibilityOff;
$postActor = Graphics::VTK::Actor->new;
$postActor->SetMapper($postMapper);
$postActor->GetProperty->SetColor(0,0,0);
$postActor->GetProperty->SetRepresentationToWireframe;
$fanComp = Graphics::VTK::StructuredGridGeometryFilter->new;
$fanComp->SetExtent(0,37,38,38,0,37);
$fanComp->SetInput($pl3d->GetOutput);
$fanMapper = Graphics::VTK::PolyDataMapper->new;
$fanMapper->SetInput($fanComp->GetOutput);
$fanActor = Graphics::VTK::Actor->new;
$fanActor->SetMapper($fanMapper);
$fanActor->GetProperty->SetColor(0,0,0);
$fanActor->GetProperty->SetRepresentationToWireframe;
# outline
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(0,0,0);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($floorActor);
$ren1->AddActor($postActor);
$ren1->AddActor($fanActor);
$aCam = Graphics::VTK::Camera->new;
$aCam->SetFocalPoint(0.00657892,0,2.41026);
$aCam->SetPosition(-1.94838,-47.1275,39.4607);
$aCam->ComputeViewPlaneNormal;
$aCam->SetViewPlaneNormal(-0.0325936,-0.785725,0.617717);
$aCam->SetViewUp(0.00653193,0.617865,0.786257);
$ren1->SetBackground(1,1,1);
$ren1->SetActiveCamera($aCam);
$renWin->SetSize(400,400);
$iren->Initialize;
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "LOxGrid.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
