#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Create dashed streamlines
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read data
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/bluntfinxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/bluntfinq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
#streamers
$seeds = Graphics::VTK::LineSource->new;
$seeds->SetResolution(25);
$seeds->SetPoint1(-6.5,0.25,0.10);
$seeds->SetPoint2(-6.5,0.25,5.0);
$streamers = Graphics::VTK::DashedStreamLine->new;
$streamers->SetInput($pl3d->GetOutput);
$streamers->SetSource($seeds->GetOutput);
$streamers->SetMaximumPropagationTime(25);
$streamers->SetStepLength(0.25);
$streamers->Update;
$mapStreamers = Graphics::VTK::PolyDataMapper->new;
$mapStreamers->SetInput($streamers->GetOutput);
$mapStreamers->SetScalarRange($pl3d->GetOutput->GetPointData->GetScalars->GetRange);
$streamersActor = Graphics::VTK::Actor->new;
$streamersActor->SetMapper($mapStreamers);
# wall
$wall = Graphics::VTK::StructuredGridGeometryFilter->new;
$wall->SetInput($pl3d->GetOutput);
$wall->SetExtent(0,100,0,0,0,100);
$wallMap = Graphics::VTK::PolyDataMapper->new;
$wallMap->SetInput($wall->GetOutput);
$wallMap->ScalarVisibilityOff;
$wallActor = Graphics::VTK::Actor->new;
$wallActor->SetMapper($wallMap);
$wallActor->GetProperty->SetColor(0.8,0.8,0.8);
# fin
$fin = Graphics::VTK::StructuredGridGeometryFilter->new;
$fin->SetInput($pl3d->GetOutput);
$fin->SetExtent(0,100,0,100,0,0);
$finMap = Graphics::VTK::PolyDataMapper->new;
$finMap->SetInput($fin->GetOutput);
$finMap->ScalarVisibilityOff;
$finActor = Graphics::VTK::Actor->new;
$finActor->SetMapper($finMap);
$finActor->GetProperty->SetColor(0.8,0.8,0.8);
# outline
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(1,1,1);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($streamersActor);
$ren1->AddActor($wallActor);
$ren1->AddActor($finActor);
$ren1->SetBackground(0,0,0);
$renWin->SetSize(700,500);
$cam1 = Graphics::VTK::Camera->new;
$cam1->SetFocalPoint(2.87956,4.24691,2.73135);
$cam1->SetPosition(-3.46307,16.7005,29.7406);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewAngle(30);
$cam1->SetViewUp(0.127555,0.911749,-0.390441);
$cam1->SetClippingRange(1,50);
$ren1->SetActiveCamera($cam1);
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
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#renWin SetFileName bluntStr.tcl.ppm
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
