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
# create planes
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
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetResolution(50,50);
$transP1 = Graphics::VTK::Transform->new;
$transP1->Translate(3.7,0.0,28.37);
$transP1->Scale(5,5,5);
$transP1->RotateY(90);
$tpd1 = Graphics::VTK::TransformPolyDataFilter->new;
$tpd1->SetInput($plane->GetOutput);
$tpd1->SetTransform($transP1);
$outTpd1 = Graphics::VTK::OutlineFilter->new;
$outTpd1->SetInput($tpd1->GetOutput);
$mapTpd1 = Graphics::VTK::PolyDataMapper->new;
$mapTpd1->SetInput($outTpd1->GetOutput);
$tpd1Actor = Graphics::VTK::Actor->new;
$tpd1Actor->SetMapper($mapTpd1);
$tpd1Actor->GetProperty->SetColor(0,0,0);
$transP2 = Graphics::VTK::Transform->new;
$transP2->Translate(9.2,0.0,31.20);
$transP2->Scale(5,5,5);
$transP2->RotateY(90);
$tpd2 = Graphics::VTK::TransformPolyDataFilter->new;
$tpd2->SetInput($plane->GetOutput);
$tpd2->SetTransform($transP2);
$outTpd2 = Graphics::VTK::OutlineFilter->new;
$outTpd2->SetInput($tpd2->GetOutput);
$mapTpd2 = Graphics::VTK::PolyDataMapper->new;
$mapTpd2->SetInput($outTpd2->GetOutput);
$tpd2Actor = Graphics::VTK::Actor->new;
$tpd2Actor->SetMapper($mapTpd2);
$tpd2Actor->GetProperty->SetColor(0,0,0);
$transP3 = Graphics::VTK::Transform->new;
$transP3->Translate(13.27,0.0,33.30);
$transP3->Scale(5,5,5);
$transP3->RotateY(90);
$tpd3 = Graphics::VTK::TransformPolyDataFilter->new;
$tpd3->SetInput($plane->GetOutput);
$tpd3->SetTransform($transP3);
$outTpd3 = Graphics::VTK::OutlineFilter->new;
$outTpd3->SetInput($tpd3->GetOutput);
$mapTpd3 = Graphics::VTK::PolyDataMapper->new;
$mapTpd3->SetInput($outTpd3->GetOutput);
$tpd3Actor = Graphics::VTK::Actor->new;
$tpd3Actor->SetMapper($mapTpd3);
$tpd3Actor->GetProperty->SetColor(0,0,0);
$appendF = Graphics::VTK::AppendPolyData->new;
$appendF->AddInput($tpd1->GetOutput);
$appendF->AddInput($tpd2->GetOutput);
$appendF->AddInput($tpd3->GetOutput);
$probe = Graphics::VTK::ProbeFilter->new;
$probe->SetInput($appendF->GetOutput);
$probe->SetSource($pl3d->GetOutput);
$contour = Graphics::VTK::ContourFilter->new;
$contour->SetInput($probe->GetOutput);
$contour->GenerateValues(50,$pl3d->GetOutput->GetScalarRange);
$contourMapper = Graphics::VTK::PolyDataMapper->new;
$contourMapper->SetInput($contour->GetOutput);
$contourMapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($contourMapper);
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
$ren1->AddActor($outlineActor);
$ren1->AddActor($planeActor);
$ren1->AddActor($tpd1Actor);
$ren1->AddActor($tpd2Actor);
$ren1->AddActor($tpd3Actor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(8.88908,0.595038,29.3342);
$cam1->SetPosition(-12.3332,31.7479,41.2387);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(0.060772,-0.319905,0.945498);
$iren->Initialize;
#renWin SetFileName "probeComb.tcl.ppm"
#renWin SaveImageAsPPM
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
