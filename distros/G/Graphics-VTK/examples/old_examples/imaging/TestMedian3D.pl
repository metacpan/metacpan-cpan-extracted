#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Test the median filter.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$median = Graphics::VTK::ImageMedian3D->new;
$median->SetInput($reader->GetOutput);
$median->SetKernelSize(7,7,1);
$median->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($median->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
# make interface
do 'WindowLevelInterface.pl';
