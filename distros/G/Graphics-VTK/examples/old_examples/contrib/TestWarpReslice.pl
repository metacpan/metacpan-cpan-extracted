#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Simple viewer for images.
$source->______imaging_examplesTcl_vtkImageInclude_tcl;
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetDataSpacing(1.0,1.0,2.0);
$reader->SetDataOrigin(-127.5,-127.5,-94);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$reader->Update;
$p1 = Graphics::VTK::Points->new;
$p2 = Graphics::VTK::Points->new;
$p1->InsertNextPoint(0,0,0);
$p2->InsertNextPoint(-60,10,20);
$p1->InsertNextPoint(-128,-128,-50);
$p2->InsertNextPoint(-128,-128,-50);
$p1->InsertNextPoint(-128,-128,50);
$p2->InsertNextPoint(-128,-128,50);
$p1->InsertNextPoint(-128,128,-50);
$p2->InsertNextPoint(-128,128,-50);
$p1->InsertNextPoint(-128,128,50);
$p2->InsertNextPoint(-128,128,50);
$p1->InsertNextPoint(128,-128,-50);
$p2->InsertNextPoint(128,-128,-50);
$p1->InsertNextPoint(128,-128,50);
$p2->InsertNextPoint(128,-128,50);
$p1->InsertNextPoint(128,128,-50);
$p2->InsertNextPoint(128,128,-50);
$p1->InsertNextPoint(128,128,50);
$p2->InsertNextPoint(128,128,50);
$transform = Graphics::VTK::ThinPlateSplineTransform->new;
$transform->SetSourceLandmarks($p1);
$transform->SetTargetLandmarks($p2);
$reslice = Graphics::VTK::ImageReslice->new;
$reslice->SetInput($reader->GetOutput);
$reslice->SetResliceTransform($transform);
$reslice->SetInterpolationModeToLinear;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($reslice->GetOutput);
$viewer->SetZSlice(90);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
#  [viewer GetImageWindow] DoubleBufferOn
$viewer->Render;
$source->______imaging_examplesTcl_WindowLevelInterface_tcl;
$windowToimage = Graphics::VTK::WindowToImageFilter->new;
$windowToimage->SetInput($viewer->GetImageWindow);
$pnmWriter = Graphics::VTK::PNMWriter->new;
$pnmWriter->SetInput($windowToimage->GetOutput);
$pnmWriter->SetFileName("TestWarpReslice.tcl.ppm");
#  pnmWriter Write
