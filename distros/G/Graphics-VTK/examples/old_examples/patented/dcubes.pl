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
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$ren2 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->PointSmoothingOn;
$renWin->AddRenderer($ren1);
$renWin->AddRenderer($ren2);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$reader = Graphics::VTK::StructuredPointsReader->new;
$reader->SetFileName("$VTK_DATA/ironProt.vtk");
#vtkRecursiveDividingCubes iso
$iso = Graphics::VTK::DividingCubes->new;
$iso->SetInput($reader->GetOutput);
$iso->SetValue(128);
$iso->SetDistance(1);
$iso->SetIncrement(1);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($iso->GetOutput);
$isoMapper->ScalarVisibilityOff;
$isoActor1 = Graphics::VTK::Actor->new;
$isoActor1->SetMapper($isoMapper);
$isoActor1->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::banana);
$isoActor1->GetProperty->SetDiffuse('.7');
$isoActor1->GetProperty->SetSpecular('.5');
$isoActor1->GetProperty->SetSpecularPower(30);
$isoActor2 = Graphics::VTK::Actor->new;
$isoActor2->SetMapper($isoMapper);
$isoActor2->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::banana);
$isoActor2->GetProperty->SetDiffuse('.7');
$isoActor2->GetProperty->SetSpecular('.5');
$isoActor2->GetProperty->SetSpecularPower(30);
$isoActor2->GetProperty->SetPointSize(5);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(@Graphics::VTK::Colors::black);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor1);
$ren1->SetBackground(1,1,1);
$ren2->AddActor($outlineActor);
$ren2->AddActor($isoActor2);
$ren2->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->SetBackground(0.1,0.2,0.4);
$ren2->SetBackground(0.1,0.2,0.4);
$ren1->SetViewport(0,0,'.5',1);
$ren2->SetViewport('.5',0,1,1);
$cam1 = Graphics::VTK::Camera->new;
$cam1->SetClippingRange(19.1589,957.946);
$cam1->SetFocalPoint(33.7014,26.706,30.5867);
$cam1->SetPosition(150.841,89.374,-107.462);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.190015,0.944614,0.267578);
$cam1->Dolly(2);
$aLight = Graphics::VTK::Light->new;
$aLight->SetPosition($cam1->GetPosition);
$aLight->SetFocalPoint($cam1->GetFocalPoint);
$ren1->SetActiveCamera($cam1);
$ren1->AddLight($aLight);
$ren2->SetActiveCamera($cam1);
$ren2->AddLight($aLight);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "dcubes.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
