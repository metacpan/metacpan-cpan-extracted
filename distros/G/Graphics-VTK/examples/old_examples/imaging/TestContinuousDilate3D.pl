#!/usr/local/bin/perl -w
#
use Graphics::VTK;

# Min of sphere around every pixel.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$dilate = Graphics::VTK::ImageContinuousDilate3D->new;
$dilate->SetInput($reader->GetOutput);
$dilate->SetKernelSize(5,5,5);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($dilate->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
#viewer DebugOn
do 'WindowLevelInterface.pl';
