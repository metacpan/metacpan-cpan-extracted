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
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$lut = Graphics::VTK::WindowLevelLookupTable->new;
$lut->SetWindow(2000);
$lut->SetLevel(1000);
# create pipeline
$reader1 = Graphics::VTK::ImageReader->new;
$reader1->SetDataByteOrderToLittleEndian;
$reader1->SetDataExtent(0,255,0,255,1,93);
$reader1->SetDataVOI(20,200,20,200,40,40);
$reader1->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader1->SetDataMask(0x7fff);
$reader1->Update;
$probePlane1 = Graphics::VTK::PlaneSource->new;
$probePlane1->SetOrigin(10,10,39);
$probePlane1->SetPoint1(210,10,39);
$probePlane1->SetPoint2(10,210,39);
$probePlane1->SetResolution(80,80);
$probe1 = Graphics::VTK::ProbeFilter->new;
$probe1->SetInput($probePlane1->GetOutput);
$probe1->SetSource($reader1->GetOutput);
$probeMapper1 = Graphics::VTK::PolyDataMapper->new;
$probeMapper1->SetInput($probe1->GetOutput);
$probeMapper1->SetScalarRange(0,1200);
$probeActor1 = Graphics::VTK::Actor->new;
$probeActor1->SetMapper($probeMapper1);
$probeActor1->GetProperty->SetRepresentationToPoints;
$probeActor1->GetProperty->SetPointSize(5);
##########
$reader2 = Graphics::VTK::ImageReader->new;
$reader2->SetDataByteOrderToLittleEndian;
$reader2->SetDataExtent(0,255,0,255,1,93);
$reader2->SetDataVOI(127,127,20,200,2,90);
$reader2->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader2->SetDataMask(0x7fff);
$reader2->Update;
$probePlane2 = Graphics::VTK::PlaneSource->new;
$probePlane2->SetOrigin(127,10,0);
$probePlane2->SetPoint1(127,10,95);
$probePlane2->SetPoint2(127,210,0);
$probePlane2->SetResolution(20,100);
$probe2 = Graphics::VTK::ProbeFilter->new;
$probe2->SetInput($probePlane2->GetOutput);
$probe2->SetSource($reader2->GetOutput);
$probe2->GetOutput->GetPointData->CopyNormalsOff;
$probeMapper2 = Graphics::VTK::PolyDataMapper->new;
$probeMapper2->SetInput($probe2->GetOutput);
$probeMapper2->SetScalarRange(0,1200);
$probeMapper2->SetLookupTable($lut);
$probeActor2 = Graphics::VTK::Actor->new;
$probeActor2->SetMapper($probeMapper2);
$probeActor2->GetProperty->SetRepresentationToPoints;
$probeActor2->GetProperty->SetPointSize(5);
##########
$reader3 = Graphics::VTK::ImageReader->new;
$reader3->SetDataByteOrderToLittleEndian;
$reader3->SetDataExtent(0,255,0,255,1,93);
$reader3->SetDataVOI(20,200,127,127,2,90);
$reader3->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader3->SetDataMask(0x7fff);
$reader3->Update;
$probePlane3 = Graphics::VTK::PlaneSource->new;
$probePlane3->SetOrigin(10,127,0);
$probePlane3->SetPoint1(10,127,95);
$probePlane3->SetPoint2(210,127,0);
$probePlane3->SetResolution(100,50);
$probe3 = Graphics::VTK::ProbeFilter->new;
$probe3->SetInput($probePlane3->GetOutput);
$probe3->SetSource($reader3->GetOutput);
$probeMapper3 = Graphics::VTK::PolyDataMapper->new;
$probeMapper3->SetInput($probe3->GetOutput);
$probeMapper3->SetScalarRange(0,1200);
$probeMapper3->SetLookupTable($lut);
$probeActor3 = Graphics::VTK::Actor->new;
$probeActor3->SetMapper($probeMapper3);
$probeActor3->GetProperty->SetRepresentationToPoints;
$probeActor3->GetProperty->SetPointSize(5);
##########
$reader4 = Graphics::VTK::ImageReader->new;
$reader4->SetDataByteOrderToLittleEndian;
$reader4->SetDataExtent(0,255,0,255,1,93);
$reader4->SetDataVOI(20,200,160,160,70,70);
$reader4->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader4->SetDataMask(0x7fff);
$reader4->Update;
$probeLine4 = Graphics::VTK::LineSource->new;
$probeLine4->SetPoint1(10,160,69);
$probeLine4->SetPoint2(210,160,69);
$probeLine4->SetResolution(30);
$probe4 = Graphics::VTK::ProbeFilter->new;
$probe4->SetInput($probeLine4->GetOutput);
$probe4->SetSource($reader4->GetOutput);
$probeMapper4 = Graphics::VTK::PolyDataMapper->new;
$probeMapper4->SetInput($probe4->GetOutput);
$probeMapper4->SetScalarRange(0,1200);
$probeActor4 = Graphics::VTK::Actor->new;
$probeActor4->SetMapper($probeMapper4);
$probeActor4->GetProperty->SetRepresentationToPoints;
$probeActor4->GetProperty->SetPointSize(10);
##########
$reader5 = Graphics::VTK::ImageReader->new;
$reader5->SetDataByteOrderToLittleEndian;
$reader5->SetDataExtent(0,255,0,255,1,93);
$reader5->SetDataVOI(160,160,20,200,70,70);
$reader5->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader5->SetDataMask(0x7fff);
$reader5->Update;
$probeLine5 = Graphics::VTK::LineSource->new;
$probeLine5->SetPoint1(160,10,69);
$probeLine5->SetPoint2(160,210,69);
$probeLine5->SetResolution(30);
$probe5 = Graphics::VTK::ProbeFilter->new;
$probe5->SetInput($probeLine5->GetOutput);
$probe5->SetSource($reader5->GetOutput);
$probeMapper5 = Graphics::VTK::PolyDataMapper->new;
$probeMapper5->SetInput($probe5->GetOutput);
$probeMapper5->SetScalarRange(0,1200);
$probeActor5 = Graphics::VTK::Actor->new;
$probeActor5->SetMapper($probeMapper5);
$probeActor5->GetProperty->SetRepresentationToPoints;
$probeActor5->GetProperty->SetPointSize(10);
##########
$reader6 = Graphics::VTK::ImageReader->new;
$reader6->SetDataByteOrderToLittleEndian;
$reader6->SetDataExtent(0,255,0,255,1,93);
$reader6->SetDataVOI(160,160,160,160,1,93);
$reader6->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader6->SetDataMask(0x7fff);
$reader6->Update;
$probeLine6 = Graphics::VTK::LineSource->new;
$probeLine6->SetPoint1(160,160,0);
$probeLine6->SetPoint2(160,160,100);
$probeLine6->SetResolution(30);
$probe6 = Graphics::VTK::ProbeFilter->new;
$probe6->SetInput($probeLine6->GetOutput);
$probe6->SetSource($reader6->GetOutput);
$probeMapper6 = Graphics::VTK::PolyDataMapper->new;
$probeMapper6->SetInput($probe6->GetOutput);
$probeMapper6->SetScalarRange(0,1200);
$probeActor6 = Graphics::VTK::Actor->new;
$probeActor6->SetMapper($probeMapper6);
$probeActor6->GetProperty->SetRepresentationToPoints;
$probeActor6->GetProperty->SetPointSize(10);
##########
$reader7 = Graphics::VTK::ImageReader->new;
$reader7->SetDataByteOrderToLittleEndian;
$reader7->SetDataExtent(0,255,0,255,1,93);
$reader7->SetDataVOI(160,160,160,160,70,70);
$reader7->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader7->SetDataMask(0x7fff);
$reader7->Update;
$vertexPoints = Graphics::VTK::Points->new;
$vertexPoints->SetNumberOfPoints(2);
$vertexPoints->InsertPoint(0,160,160,69);
$vertexPoints->InsertPoint(1,161,161,70);
$aCell = Graphics::VTK::CellArray->new;
$aCell->InsertNextCell(1);
$aCell->InsertCellPoint(0);
$aCell->InsertNextCell(1);
$aCell->InsertCellPoint(1);
$aPolyData = Graphics::VTK::PolyData->new;
$aPolyData->SetPoints($vertexPoints);
$aPolyData->SetVerts($aCell);
$probe7 = Graphics::VTK::ProbeFilter->new;
$probe7->SetInput($aPolyData);
$probe7->SetSource($reader7->GetOutput);
$probeMapper7 = Graphics::VTK::DataSetMapper->new;
$probeMapper7->SetInput($probe7->GetOutput);
$probeMapper7->SetScalarRange(0,1200);
$probeActor7 = Graphics::VTK::Actor->new;
$probeActor7->SetMapper($probeMapper7);
$probeActor7->GetProperty->SetPointSize(20);
$probeActor7->GetProperty->SetRepresentationToPoints;
##########
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader1->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
$ren1->AddActor($outlineActor);
$ren1->AddActor($probeActor1);
$ren1->AddActor($probeActor2);
$ren1->AddActor($probeActor3);
$ren1->AddActor($probeActor4);
$ren1->AddActor($probeActor5);
$ren1->AddActor($probeActor6);
$ren1->AddActor($probeActor7);
$ren1->SetBackground('.7','.8',1);
$probeActor1->SetScale('.8','.8',1.5);
$probeActor2->SetScale('.8','.8',1.5);
$probeActor3->SetScale('.8','.8',1.5);
$probeActor4->SetScale('.8','.8',1.5);
$probeActor5->SetScale('.8','.8',1.5);
$probeActor6->SetScale('.8','.8',1.5);
$probeActor7->SetScale('.8','.8',1.5);
$outlineActor->SetScale('.8','.8',1.5);
#probeActor1 VisibilityOff
#probeActor2 VisibilityOff
#probeActor3 VisibilityOff
#probeActor4 VisibilityOff
#probeActor5 VisibilityOff
#probeActor6 VisibilityOff
#outlineActor VisibilityOff
$cullers = $ren1->GetCullers;
$cullers->InitTraversal;
$culler = $cullers->GetNextItem;
$culler->SetMinimumCoverage(0);
$ren1->GetActiveCamera->SetPosition(343.234,268.558,190.754);
$ren1->GetActiveCamera->SetFocalPoint(88,88,75);
$ren1->GetActiveCamera->SetViewAngle(30);
$ren1->GetActiveCamera->SetViewUp(0,0,1);
$ren1->GetActiveCamera->SetViewPlaneNormal(0.765587,0.541592,0.34721);
$ren1->GetActiveCamera->SetClippingRange(170.497,496.27);
$renWin->SetSize(500,500);
$iren->Initialize;
$renWin->SetFileName("probeImageData2.tcl.ppm");
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
