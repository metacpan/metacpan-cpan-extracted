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
# read data
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/bluntfinxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/bluntfinq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
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
# planes to connect
$plane1 = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane1->SetInput($pl3d->GetOutput);
$plane1->SetExtent(10,10,0,100,0,100);
$conn = Graphics::VTK::PolyDataConnectivityFilter->new;
$conn->SetInput($plane1->GetOutput);
$conn->ScalarConnectivityOn;
$conn->SetScalarRange(1.5,4.0);
$plane1Map = Graphics::VTK::PolyDataMapper->new;
$plane1Map->SetInput($conn->GetOutput);
$plane1Map->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$plane1Actor = Graphics::VTK::Actor->new;
$plane1Actor->SetMapper($plane1Map);
$plane1Actor->GetProperty->SetOpacity(0.999);
# outline
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(0,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($wallActor);
$ren1->AddActor($finActor);
$ren1->AddActor($plane1Actor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(400,400);
$cam1 = Graphics::VTK::Camera->new;
$cam1->SetClippingRange(1.51176,75.5879);
$cam1->SetFocalPoint(2.33749,2.96739,3.61023);
$cam1->SetPosition(10.8787,5.27346,15.8687);
$cam1->SetViewAngle(30);
$cam1->SetViewPlaneNormal(0.564986,0.152542,0.810877);
$cam1->SetViewUp(-0.0610856,0.987798,-0.143262);
$ren1->SetActiveCamera($cam1);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("polyConn.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
