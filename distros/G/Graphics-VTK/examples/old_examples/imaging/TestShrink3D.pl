#!/usr/local/bin/perl -w
#
use Graphics::VTK;

# Halves the size of the image in the x, Y and Z dimensions.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$shrink = Graphics::VTK::ImageShrink3D->new;
$shrink->SetInput($reader->GetOutput);
$shrink->SetShrinkFactors(2,2,2);
$shrink->AveragingOff;
#shrink SetProgressMethod {set pro [shrink GetProgress]; puts "Completed $pro"; flush stdout}
#shrink Update
$shrink->SetNumberOfThreads(1);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($shrink->GetOutput);
$viewer->SetZSlice(11);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
# make interface
do 'WindowLevelInterface.pl';
