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
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$vx = Graphics::VTK::ExtractVectorComponents->new;
$vx->SetInput($pl3d->GetOutput);
$isoVx = Graphics::VTK::ContourFilter->new;
$isoVx->SetInput($vx->GetVxComponent);
$isoVx->SetValue(0,'.38');
$normalsVx = Graphics::VTK::PolyDataNormals->new;
$normalsVx->SetInput($isoVx->GetOutput);
$normalsVx->SetFeatureAngle(45);
$normalsVx->SetMaxRecursionDepth(100);
$isoVxMapper = Graphics::VTK::PolyDataMapper->new;
$isoVxMapper->SetInput($normalsVx->GetOutput);
$isoVxMapper->ScalarVisibilityOff;
$isoVxMapper->ImmediateModeRenderingOn;
$isoVxActor = Graphics::VTK::Actor->new;
$isoVxActor->SetMapper($isoVxMapper);
$isoVxActor->GetProperty->SetColor(@Graphics::VTK::Colors::tomato);
$vy = Graphics::VTK::ExtractVectorComponents->new;
$vy->SetInput($pl3d->GetOutput);
$isoVy = Graphics::VTK::ContourFilter->new;
$isoVy->SetInput($vy->GetVyComponent);
$isoVy->SetValue(0,'.38');
$normalsVy = Graphics::VTK::PolyDataNormals->new;
$normalsVy->SetInput($isoVy->GetOutput);
$normalsVy->SetFeatureAngle(45);
$normalsVy->SetMaxRecursionDepth(100);
$isoVyMapper = Graphics::VTK::PolyDataMapper->new;
$isoVyMapper->SetInput($normalsVy->GetOutput);
$isoVyMapper->ScalarVisibilityOff;
$isoVyMapper->ImmediateModeRenderingOn;
$isoVyActor = Graphics::VTK::Actor->new;
$isoVyActor->SetMapper($isoVyMapper);
$isoVyActor->GetProperty->SetColor(@Graphics::VTK::Colors::lime_green);
$vz = Graphics::VTK::ExtractVectorComponents->new;
$vz->SetInput($pl3d->GetOutput);
$isoVz = Graphics::VTK::ContourFilter->new;
$isoVz->SetInput($vz->GetVzComponent);
$isoVz->SetValue(0,'.38');
$normalsVz = Graphics::VTK::PolyDataNormals->new;
$normalsVz->SetInput($isoVz->GetOutput);
$normalsVz->SetFeatureAngle(45);
$normalsVz->SetMaxRecursionDepth(100);
$isoVzMapper = Graphics::VTK::PolyDataMapper->new;
$isoVzMapper->SetInput($normalsVz->GetOutput);
$isoVzMapper->ScalarVisibilityOff;
$isoVzMapper->ImmediateModeRenderingOn;
$isoVzActor = Graphics::VTK::Actor->new;
$isoVzActor->SetMapper($isoVzMapper);
$isoVzActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoVxActor);
$isoVxActor->AddPosition(0,12,0);
$ren1->AddActor($isoVyActor);
$ren1->AddActor($isoVzActor);
$isoVzActor->AddPosition(0,-12,0);
$ren1->SetBackground('.8','.8','.8');
$renWin->SetSize(321,321);
$ren1->GetActiveCamera->SetPosition(-63.3093,-1.55444,64.3922);
$ren1->GetActiveCamera->SetFocalPoint(8.255,0.0499763,29.7631);
$ren1->GetActiveCamera->SetViewAngle(30);
$ren1->GetActiveCamera->SetViewUp(0,0,1);
$ren1->GetActiveCamera->ComputeViewPlaneNormal;
$ren1->ResetCameraClippingRange;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "extractVectors.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
