#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Simple viewer for images.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$permute = Graphics::VTK::ImagePermute->new;
$permute->SetInput($reader->GetOutput);
$permute->SetFilteredAxes($VTK_IMAGE_Y_AXIS,$VTK_IMAGE_Z_AXIS,$VTK_IMAGE_X_AXIS);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($permute->GetOutput);
$viewer->SetZSlice(128);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
#viewer DebugOn
#viewer Render
#make interface
do 'WindowLevelInterface.pl';
