#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Halves the size of the image in the x, Y and Z dimensions.
# Computes the whole volume, but streams the input using the streaming
# functionality in vtkImageFilter class.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader SetStartMethod {puts "reading: [[reader GetOutput] GetUpdateExtent]"}
$shrink = Graphics::VTK::ImageShrink3D->new;
$shrink->SetInput($reader->GetOutput);
$shrink->SetShrinkFactors(2,2,2);
$shrink->AveragingOn;
#shrink DebugOn
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($shrink->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(3000);
$viewer->SetColorLevel(1500);
#make interface
do 'WindowLevelInterface.pl';
