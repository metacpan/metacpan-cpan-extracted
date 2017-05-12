#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
#reader DebugOn
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$gradient = Graphics::VTK::ImageGradientMagnitude->new;
$gradient->SetDimensionality(3);
$gradient->SetInput($reader->GetOutput);
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($gradient->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(1000);
$viewer->SetColorLevel(500);
# make interface
do 'WindowLevelInterface.pl';
