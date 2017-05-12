#!/usr/local/bin/perl -w
#
use Graphics::VTK;

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
$flip = Graphics::VTK::ImageFlip->new;
$flip->SetInput($reader->GetOutput);
$flip->SetFilteredAxes($VTK_IMAGE_X_AXIS);
#flip BypassOn
#flip PreserveImageExtentOn
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($flip->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
#make interface
do 'WindowLevelInterface.pl';
