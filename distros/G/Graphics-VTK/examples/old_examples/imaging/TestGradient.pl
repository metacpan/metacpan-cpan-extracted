#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script is for testing the 2d Gradient filter.
# It only displays the first component (0) which contains
# the magnitude of the gradient.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
#reader DebugOn
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$gradient = Graphics::VTK::ImageGradient->new;
$gradient->SetInput($reader->GetOutput);
$gradient->SetDimensionality(3);
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($gradient->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(400);
$viewer->SetColorLevel(0);
#make interface
do 'WindowLevelInterface.pl';
