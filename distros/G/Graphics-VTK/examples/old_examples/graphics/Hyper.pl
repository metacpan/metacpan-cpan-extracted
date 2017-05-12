#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# generate four hyperstreamlines
# get the supporting scripts
use Graphics::VTK::Tk::vtkInt;
#source $VTK_TCL/vtkInclude.tcl
# create tensor ellipsoids
# Create the RenderWindow, Renderer and interactive renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Create tensor ellipsoids
# generate tensors
$ptLoad = Graphics::VTK::PointLoad->new;
$ptLoad->SetLoadValue(100.0);
$ptLoad->SetSampleDimensions(30,30,30);
$ptLoad->ComputeEffectiveStressOn;
$ptLoad->SetModelBounds(-10,10,-10,10,-10,10);
# Generate hyperstreamlines
$s1 = Graphics::VTK::HyperStreamline->new;
$s1->SetInput($ptLoad->GetOutput);
$s1->SetStartPosition(9,9,-9);
$s1->IntegrateMinorEigenvector;
$s1->SetMaximumPropagationDistance(18.0);
$s1->SetIntegrationStepLength(0.1);
$s1->SetStepLength(0.01);
$s1->SetRadius(0.25);
$s1->SetNumberOfSides(18);
$s1->SetIntegrationDirection($VTK_INTEGRATE_BOTH_DIRECTIONS);
$s1->Update;
# Map hyperstreamlines
$lut = Graphics::VTK::LogLookupTable->new;
$lut->SetHueRange('.6667',0.0);
$s1Mapper = Graphics::VTK::PolyDataMapper->new;
$s1Mapper->SetInput($s1->GetOutput);
$s1Mapper->SetLookupTable($lut);
$ptLoad->Update;
#force update for scalar range
$s1Mapper->SetScalarRange($ptLoad->GetOutput->GetScalarRange);
$s1Actor = Graphics::VTK::Actor->new;
$s1Actor->SetMapper($s1Mapper);
$s2 = Graphics::VTK::HyperStreamline->new;
$s2->SetInput($ptLoad->GetOutput);
$s2->SetStartPosition(-9,-9,-9);
$s2->IntegrateMinorEigenvector;
$s2->SetMaximumPropagationDistance(18.0);
$s2->SetIntegrationStepLength(0.1);
$s2->SetStepLength(0.01);
$s2->SetRadius(0.25);
$s2->SetNumberOfSides(18);
$s2->SetIntegrationDirection($VTK_INTEGRATE_BOTH_DIRECTIONS);
$s2->Update;
$s2Mapper = Graphics::VTK::PolyDataMapper->new;
$s2Mapper->SetInput($s2->GetOutput);
$s2Mapper->SetLookupTable($lut);
$ptLoad->Update;
#force update for scalar range
$s2Mapper->SetScalarRange($ptLoad->GetOutput->GetScalarRange);
$s2Actor = Graphics::VTK::Actor->new;
$s2Actor->SetMapper($s2Mapper);
$s3 = Graphics::VTK::HyperStreamline->new;
$s3->SetInput($ptLoad->GetOutput);
$s3->SetStartPosition(9,-9,-9);
$s3->IntegrateMinorEigenvector;
$s3->SetMaximumPropagationDistance(18.0);
$s3->SetIntegrationStepLength(0.1);
$s3->SetStepLength(0.01);
$s3->SetRadius(0.25);
$s3->SetNumberOfSides(18);
$s3->SetIntegrationDirection($VTK_INTEGRATE_BOTH_DIRECTIONS);
$s3->Update;
$s3Mapper = Graphics::VTK::PolyDataMapper->new;
$s3Mapper->SetInput($s3->GetOutput);
$s3Mapper->SetLookupTable($lut);
$ptLoad->Update;
#force update for scalar range
$s3Mapper->SetScalarRange($ptLoad->GetOutput->GetScalarRange);
$s3Actor = Graphics::VTK::Actor->new;
$s3Actor->SetMapper($s3Mapper);
$s4 = Graphics::VTK::HyperStreamline->new;
$s4->SetInput($ptLoad->GetOutput);
$s4->SetStartPosition(-9,9,-9);
$s4->IntegrateMinorEigenvector;
$s4->SetMaximumPropagationDistance(18.0);
$s4->SetIntegrationStepLength(0.1);
$s4->SetStepLength(0.01);
$s4->SetRadius(0.25);
$s4->SetNumberOfSides(18);
$s4->SetIntegrationDirection($VTK_INTEGRATE_BOTH_DIRECTIONS);
$s4->Update;
$s4Mapper = Graphics::VTK::PolyDataMapper->new;
$s4Mapper->SetInput($s4->GetOutput);
$s4Mapper->SetLookupTable($lut);
$ptLoad->Update;
#force update for scalar range
$s4Mapper->SetScalarRange($ptLoad->GetOutput->GetScalarRange);
$s4Actor = Graphics::VTK::Actor->new;
$s4Actor->SetMapper($s4Mapper);
# plane for context
$g = Graphics::VTK::StructuredPointsGeometryFilter->new;
$g->SetInput($ptLoad->GetOutput);
$g->SetExtent(0,100,0,100,0,0);
$g->Update;
#for scalar range
$gm = Graphics::VTK::PolyDataMapper->new;
$gm->SetInput($g->GetOutput);
$gm->SetScalarRange($g->GetOutput->GetScalarRange);
$ga = Graphics::VTK::Actor->new;
$ga->SetMapper($gm);
# Create outline around data
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($ptLoad->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
# Create cone indicating application of load
$coneSrc = Graphics::VTK::ConeSource->new;
$coneSrc->SetRadius('.5');
$coneSrc->SetHeight(2);
$coneMap = Graphics::VTK::PolyDataMapper->new;
$coneMap->SetInput($coneSrc->GetOutput);
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMap);
$coneActor->SetPosition(0,0,11);
$coneActor->RotateY(90);
$coneActor->GetProperty->SetColor(1,0,0);
$camera = Graphics::VTK::Camera->new;
$camera->SetFocalPoint(0.113766,-1.13665,-1.01919);
$camera->SetPosition(-29.4886,-63.1488,26.5807);
$camera->ComputeViewPlaneNormal;
$camera->SetViewAngle(24.4617);
$camera->SetViewUp(0.17138,0.331163,0.927879);
$camera->SetClippingRange(1,100);
$ren1->AddActor($s1Actor);
$ren1->AddActor($s2Actor);
$ren1->AddActor($s3Actor);
$ren1->AddActor($s4Actor);
$ren1->AddActor($outlineActor);
$ren1->AddActor($coneActor);
$ren1->AddActor($ga);
$ren1->SetBackground(1.0,1.0,1.0);
$ren1->SetActiveCamera($camera);
$renWin->SetSize(500,500);
$renWin->Render;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName Hyper.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
