#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script is for testing the 3D Sobel filter.
# Displays the 3 components using color.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
#reader DebugOn
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$sobel = Graphics::VTK::ImageSobel2D->new;
$sobel->SetInput($reader->GetOutput);
$sobel->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($sobel->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(400);
$viewer->SetColorLevel(0);
# make interface
do 'WindowLevelInterface.pl';
