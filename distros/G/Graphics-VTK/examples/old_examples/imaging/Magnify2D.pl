#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Doubles the size of the image in the X and Y dimensions.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
#reader DebugOn
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$magnify = Graphics::VTK::ImageMagnify->new;
$magnify->SetInput($reader->GetOutput);
$magnify->SetMagnificationFactors(2,2,1);
$magnify->InterpolateOn;
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($magnify->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(3000);
$viewer->SetColorLevel(1500);
#make interface
do 'WindowLevelInterface.pl';
