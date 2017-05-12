#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate the use of the cube axes
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# read in an interesting object and outline it
$fohe = Graphics::VTK::BYUReader->new;
$fohe->SetGeometryFileName("$VTK_DATA/fohe.g");
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($fohe->GetOutput);
$foheMapper = Graphics::VTK::PolyDataMapper->new;
$foheMapper->SetInput($normals->GetOutput);
$foheActor = Graphics::VTK::LODActor->new;
$foheActor->SetMapper($foheMapper);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($normals->GetOutput);
$mapOutline = Graphics::VTK::PolyDataMapper->new;
$mapOutline->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($mapOutline);
$outlineActor->GetProperty->SetColor(0,0,0);
# Create the RenderWindow, Renderer, and setup viewports
$camera = Graphics::VTK::Camera->new;
$camera->SetClippingRange(2.7,195);
$camera->SetFocalPoint(128.4,86.5,223.17);
$camera->SetPosition(145.927,68.5,212.686);
$camera->ComputeViewPlaneNormal;
$camera->SetViewUp(0.6556,0.739704,-0.19305);
$light = Graphics::VTK::Light->new;
$light->SetFocalPoint(128.4,86.5,223.17);
$light->SetPosition(145.927,68.5,212.686);
$ren1 = Graphics::VTK::Renderer->new;
$ren1->SetViewport(0,0,0.5,1.0);
$ren1->SetActiveCamera($camera);
$ren1->AddLight($light);
$ren2 = Graphics::VTK::Renderer->new;
$ren2->SetViewport(0.5,0,1.0,1.0);
$ren2->SetActiveCamera($camera);
$ren2->AddLight($light);
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->AddRenderer($ren2);
$renWin->SetWindowName("vtk - Cube Axes");
$renWin->SetSize(600,300);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddProp($foheActor);
$ren1->AddProp($outlineActor);
$ren2->AddProp($foheActor);
$ren2->AddProp($outlineActor);
$ren1->SetBackground(0.1,0.2,0.4);
$ren2->SetBackground(0.1,0.2,0.4);
$axes = Graphics::VTK::CubeAxesActor2D->new;
$axes->SetInput($normals->GetOutput);
$axes->SetCamera($ren1->GetActiveCamera);
$axes->SetLabelFormat("%6.4g");
$axes->ShadowOn;
$axes->SetFlyModeToOuterEdges;
$axes->SetFontFactor(0.8);
$axes->GetProperty->SetColor(1,1,1);
$ren1->AddProp($axes);
$axes2 = Graphics::VTK::CubeAxesActor2D->new;
$axes2->SetProp($foheActor);
$axes2->SetCamera($ren2->GetActiveCamera);
$axes2->SetLabelFormat("%6.4g");
$axes2->ShadowOn;
$axes2->SetFlyModeToClosestTriad;
$axes2->SetFontFactor(0.8);
$axes2->GetProperty->SetColor(1,1,1);
$ren2->AddProp($axes2);
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#
sub TkCheckAbort
{
 my $foo;
 $foo = $renWin->GetEventPending;
 $renWin->SetAbortRender(1) if ($foo != 0);
}
$renWin->SetAbortCheckMethod(
 sub
  {
   TkCheckAbort();
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
