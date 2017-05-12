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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$ren2 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->AddRenderer($ren2);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(110);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$probeLine = Graphics::VTK::LineSource->new;
$probeLine->SetPoint1(1,1,29);
$probeLine->SetPoint2(16.5,5,31.7693);
$probeLine->SetResolution(500);
$probe = Graphics::VTK::ProbeFilter->new;
$probe->SetInput($probeLine->GetOutput);
$probe->SetSource($pl3d->GetOutput);
$probeTube = Graphics::VTK::TubeFilter->new;
$probeTube->SetInput($probe->GetPolyDataOutput);
$probeTube->SetNumberOfSides(5);
$probeTube->SetRadius('.05');
$probeMapper = Graphics::VTK::PolyDataMapper->new;
$probeMapper->SetInput($probeTube->GetOutput);
$probeMapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$probeActor = Graphics::VTK::Actor->new;
$probeActor->SetMapper($probeMapper);
$displayLine = Graphics::VTK::LineSource->new;
$displayLine->SetPoint1(0,0,0);
$displayLine->SetPoint2(1,0,0);
$displayLine->SetResolution($probeLine->GetResolution);
$displayMerge = Graphics::VTK::MergeFilter->new;
$displayMerge->SetGeometry($displayLine->GetOutput);
$displayMerge->SetScalars($probe->GetPolyDataOutput);
$displayWarp = Graphics::VTK::WarpScalar->new;
$displayWarp->SetInput($displayMerge->GetPolyDataOutput);
$displayWarp->SetNormal(0,1,0);
$displayWarp->SetScaleFactor('.000001');
$displayMapper = Graphics::VTK::PolyDataMapper->new;
$displayMapper->SetInput($displayWarp->GetPolyDataOutput);
$displayMapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$displayActor = Graphics::VTK::Actor->new;
$displayActor->SetMapper($displayMapper);
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
$ren1->AddActor($outlineActor);
$ren1->AddActor($probeActor);
$ren1->SetBackground(1,1,1);
$ren1->SetViewport(0,'.25',1,1);
$ren2->AddActor($displayActor);
$ren2->SetBackground(0,0,0);
$ren2->SetViewport(0,0,1,'.25');
$renWin->SetSize(500,500);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(8.88908,0.595038,29.3342);
$cam1->SetPosition(9.9,-26,41);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(0.060772,-0.319905,0.945498);
$cam2 = $ren2->GetActiveCamera;
$cam2->ParallelProjectionOn;
$cam2->SetParallelScale('.15');
$iren->Initialize;
#renWin SetFileName "mergeFilter.tcl.ppm"
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
