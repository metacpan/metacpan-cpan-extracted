#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script shows the magnitude of an image in frequency domain.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,0,92);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$gradient = Graphics::VTK::ImageGradient->new;
$gradient->SetInput($reader->GetOutput);
$gradient->SetDimensionality(3);
#gradient DebugOn
$magnitude = Graphics::VTK::ImageMagnitude->new;
$magnitude->SetInput($gradient->GetOutput);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($magnitude->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(1000);
$viewer->SetColorLevel(200);
#viewer DebugOn
#make interface
do 'WindowLevelInterface.pl';
