#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test the threshold filter.
# Values above 2000 are set to 255.
# Values below 2000 are set to 0.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$reader->SetDataScalarType($VTK_SHORT);
#reader DebugOn
$thresh = Graphics::VTK::ImageThreshold->new;
$thresh->SetInput($reader->GetOutput);
$thresh->ThresholdByUpper(2000.0);
$thresh->SetInValue(255);
$thresh->SetOutValue(0);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($thresh->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
