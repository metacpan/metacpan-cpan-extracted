#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script is for testing the Nd Gaussian Smooth filter.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
#reader DebugOn
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$smooth = Graphics::VTK::ImageGaussianSmooth->new;
$smooth->SetInput($reader->GetOutput);
$smooth->SetDimensionality(2);
$smooth->SetStandardDeviations(2,10);
$smooth->BypassOn;
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($smooth->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
$viewer->Render;
$smooth->BypassOff;
$viewer->Render;
$smooth->Modified;
$viewer->Render;
$smooth->Modified;
$viewer->Render;
$smooth->Modified;
$viewer->Render;
# make interface
do 'WindowLevelInterface.pl';
