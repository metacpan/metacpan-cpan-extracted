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
# planes to threshold
$plane1 = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane1->SetInput($pl3d->GetOutput);
$plane1->SetExtent(10,10,0,100,0,100);
$plane1Map = Graphics::VTK::PolyDataMapper->new;
$plane1Map->SetInput($plane1->GetOutput);
$pl3dPtData = $pl3d->GetOutput->GetPointData;
$pl3dScalars = $pl3dPtData->GetScalars;
$plane1Map->SetScalarRange($pl3dScalars->GetRange);
$plane1Actor = Graphics::VTK::Actor->new;
$plane1Actor->SetMapper($plane1Map);
$plane2 = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane2->SetInput($pl3d->GetOutput);
$plane2->SetExtent(25,25,0,100,0,100);
$plane2Map = Graphics::VTK::PolyDataMapper->new;
$plane2Map->SetInput($plane2->GetOutput);
$plane2Map->SetScalarRange($pl3d->GetOutput->GetPointData->GetScalars->GetRange);
$plane2Actor = Graphics::VTK::Actor->new;
$plane2Actor->SetMapper($plane2Map);
$plane3 = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane3->SetInput($pl3d->GetOutput);
$plane3->SetExtent(35,35,0,100,0,100);
$plane3Map = Graphics::VTK::DataSetMapper->new;
$plane3Map->SetInput($plane3->GetOutput);
$plane3Map->SetScalarRange($pl3d->GetOutput->GetPointData->GetScalars->GetRange);
$plane3Actor = Graphics::VTK::Actor->new;
$plane3Actor->SetMapper($plane3Map);
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
$ren1->AddActor($plane2Actor);
$ren1->AddActor($plane3Actor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$cam1 = $ren1->GetActiveCamera;
$cam1->Azimuth(-40);
$cam1->Zoom(1.4);
$ren1->ResetCameraClippingRange;
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#renWin SetFileName bluntF.tcl.ppm
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
