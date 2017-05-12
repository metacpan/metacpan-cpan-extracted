#!/usr/local/bin/perl -w
#
use Graphics::VTK;

# Divergence measures rate of change of gradient.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$gradient = Graphics::VTK::ImageGradient->new;
$gradient->SetDimensionality(3);
$gradient->SetInput($reader->GetOutput);
$derivative = Graphics::VTK::ImageDivergence->new;
$derivative->SetInput($gradient->GetOutput);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($derivative->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(1000);
$viewer->SetColorLevel(0);
# make interface
do 'WindowLevelInterface.pl';
