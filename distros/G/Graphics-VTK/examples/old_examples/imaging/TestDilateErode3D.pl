#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test DilationErode filter
# First the image is thresholded.
# It is the dilated with a spher of radius 5.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$thresh = Graphics::VTK::ImageThreshold->new;
$thresh->SetInput($reader->GetOutput);
$thresh->ThresholdByUpper(2000.0);
$thresh->SetInValue(255);
$thresh->SetOutValue(0);
$dilate = Graphics::VTK::ImageDilateErode3D->new;
$dilate->SetInput($thresh->GetOutput);
$dilate->SetDilateValue(255);
$dilate->SetErodeValue(0);
$dilate->SetKernelSize(5,5,5);
$dilate->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($dilate->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
