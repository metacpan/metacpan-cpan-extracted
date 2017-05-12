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
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetDataVOI(20,200,20,200,40,40);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$reader->Update;
$probeLine = Graphics::VTK::LineSource->new;
$probeLine->SetPoint1(25,25,39);
$probeLine->SetPoint2(150,150,39);
$probeLine->SetPoint1(10,10,39);
$probeLine->SetPoint2(210,210,39);
$probeLine->SetResolution(100);
$probe = Graphics::VTK::ProbeFilter->new;
$probe->SetInput($probeLine->GetOutput);
$probe->SetSource($reader->GetOutput);
$probeTube = Graphics::VTK::TubeFilter->new;
$probeTube->SetInput($probe->GetPolyDataOutput);
$probeTube->SetNumberOfSides(5);
$probeTube->SetRadius(1);
$probeMapper = Graphics::VTK::PolyDataMapper->new;
$probeMapper->SetInput($probeTube->GetOutput);
$probeMapper->SetScalarRange($reader->GetOutput->GetScalarRange);
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
$displayWarp->SetScaleFactor('.00005');
$displayMapper = Graphics::VTK::PolyDataMapper->new;
$displayMapper->SetInput($displayWarp->GetPolyDataOutput);
$displayMapper->SetScalarRange($reader->GetOutput->GetScalarRange);
$displayActor = Graphics::VTK::Actor->new;
$displayActor->SetMapper($displayMapper);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
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
$cam2 = $ren2->GetActiveCamera;
$cam2->ParallelProjectionOn;
$cam2->SetParallelScale('.15');
$iren->Initialize;
$renWin->SetFileName("probeImageData.tcl.ppm");
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
