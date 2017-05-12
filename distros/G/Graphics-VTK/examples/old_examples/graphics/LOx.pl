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
$pl3d->SetScalarFunctionNumber(153);
$pl3d->SetVectorFunctionNumber(200);
$pl3d->Update;
#blue to red lut
$lut = Graphics::VTK::LookupTable->new;
$lut->SetHueRange(0.667,0.0);
# computational planes
$floorComp = Graphics::VTK::StructuredGridGeometryFilter->new;
$floorComp->SetExtent(0,37,0,75,0,0);
$floorComp->SetInput($pl3d->GetOutput);
$floorComp->Update;
$floorMapper = Graphics::VTK::PolyDataMapper->new;
$floorMapper->SetInput($floorComp->GetOutput);
$floorMapper->ScalarVisibilityOff;
$floorMapper->SetLookupTable($lut);
$floorActor = Graphics::VTK::Actor->new;
$floorActor->SetMapper($floorMapper);
$floorActor->GetProperty->SetRepresentationToWireframe;
$floorActor->GetProperty->SetColor(0,0,0);
$subFloorComp = Graphics::VTK::StructuredGridGeometryFilter->new;
$subFloorComp->SetExtent(0,37,0,15,22,22);
$subFloorComp->SetInput($pl3d->GetOutput);
$subFloorMapper = Graphics::VTK::PolyDataMapper->new;
$subFloorMapper->SetInput($subFloorComp->GetOutput);
$subFloorMapper->SetLookupTable($lut);
$subFloorMapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$subFloorActor = Graphics::VTK::Actor->new;
$subFloorActor->SetMapper($subFloorMapper);
$subFloor2Comp = Graphics::VTK::StructuredGridGeometryFilter->new;
$subFloor2Comp->SetExtent(0,37,60,75,22,22);
$subFloor2Comp->SetInput($pl3d->GetOutput);
$subFloor2Mapper = Graphics::VTK::PolyDataMapper->new;
$subFloor2Mapper->SetInput($subFloor2Comp->GetOutput);
$subFloor2Mapper->SetLookupTable($lut);
$subFloor2Mapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$subFloor2Actor = Graphics::VTK::Actor->new;
$subFloor2Actor->SetMapper($subFloor2Mapper);
$postComp = Graphics::VTK::StructuredGridGeometryFilter->new;
$postComp->SetExtent(10,10,0,75,0,37);
$postComp->SetInput($pl3d->GetOutput);
$postMapper = Graphics::VTK::PolyDataMapper->new;
$postMapper->SetInput($postComp->GetOutput);
$postMapper->SetLookupTable($lut);
$postMapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$postActor = Graphics::VTK::Actor->new;
$postActor->SetMapper($postMapper);
$postActor->GetProperty->SetColor(0,0,0);
$fanComp = Graphics::VTK::StructuredGridGeometryFilter->new;
$fanComp->SetExtent(0,37,38,38,0,37);
$fanComp->SetInput($pl3d->GetOutput);
$fanMapper = Graphics::VTK::PolyDataMapper->new;
$fanMapper->SetInput($fanComp->GetOutput);
$fanMapper->SetLookupTable($lut);
$fanMapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$fanActor = Graphics::VTK::Actor->new;
$fanActor->SetMapper($fanMapper);
$fanActor->GetProperty->SetColor(0,0,0);
# streamers
# spherical seed points
$rake = Graphics::VTK::PointSource->new;
$rake->SetCenter(-0.74,0,0.3);
$rake->SetNumberOfPoints(10);
# a line of seed points
$seedsComp = Graphics::VTK::StructuredGridGeometryFilter->new;
$seedsComp->SetExtent(10,10,37,39,1,35);
$seedsComp->SetInput($pl3d->GetOutput);
$streamers = Graphics::VTK::StreamLine->new;
$streamers->SetInput($pl3d->GetOutput);
#    streamers SetSource [rake GetOutput]
$streamers->SetSource($seedsComp->GetOutput);
$streamers->SetMaximumPropagationTime(250);
$streamers->SpeedScalarsOn;
$streamers->SetIntegrationStepLength('.2');
$streamers->SetStepLength('.25');
$streamers->SetNumberOfThreads(1);
$tubes = Graphics::VTK::TubeFilter->new;
$tubes->SetInput($streamers->GetOutput);
$tubes->SetNumberOfSides(8);
$tubes->SetRadius('.08');
$tubes->SetVaryRadius(0);
$mapTubes = Graphics::VTK::PolyDataMapper->new;
$mapTubes->SetInput($tubes->GetOutput);
$mapTubes->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$tubesActor = Graphics::VTK::Actor->new;
$tubesActor->SetMapper($mapTubes);
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
$ren1->AddActor($subFloorActor);
$ren1->AddActor($subFloor2Actor);
$ren1->AddActor($postActor);
$ren1->AddActor($fanActor);
$ren1->AddActor($tubesActor);
$aCam = Graphics::VTK::Camera->new;
$aCam->SetFocalPoint(0.00657892,0,2.41026);
$aCam->SetPosition(-1.94838,-47.1275,39.4607);
$aCam->ComputeViewPlaneNormal;
$aCam->SetViewPlaneNormal(-0.0325936,-0.785725,0.617717);
$aCam->SetViewUp(0.00653193,0.617865,0.786257);
$aCam->SetClippingRange(1,100);
$ren1->SetBackground('.1','.2','.4');
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
#renWin SetFileName "LOx.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
