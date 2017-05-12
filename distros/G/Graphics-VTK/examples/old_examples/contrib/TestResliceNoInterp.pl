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
$reader->SetDataOrigin(-127.5,-127.5,-47);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$reader->Update;
$transform = Graphics::VTK::Transform->new;
$transform->RotateX(10);
$transform->RotateY(20);
$transform->RotateZ(30);
$reslice = Graphics::VTK::ImageReslice->new;
$reslice->SetInput($reader->GetOutput);
$reslice->SetResliceTransform($transform);
$reslice->InterpolateOff;
$reslice->SetBackgroundLevel(1023);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($reslice->GetOutput);
$viewer->SetZSlice(120);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
$viewer->Render;
$source->______imaging_examplesTcl_WindowLevelInterface_tcl;
$windowToimage = Graphics::VTK::WindowToImageFilter->new;
$windowToimage->SetInput($viewer->GetImageWindow);
$pnmWriter = Graphics::VTK::PNMWriter->new;
$pnmWriter->SetInput($windowToimage->GetOutput);
$pnmWriter->SetFileName("TestReslice.tcl.ppm");
#  pnmWriter Write
