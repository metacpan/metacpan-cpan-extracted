#!/usr/local/bin/perl -w
#
use Graphics::VTK;

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
$laplacian = Graphics::VTK::ImageLaplacian->new;
$laplacian->SetDimensionality(3);
$laplacian->SetInput($reader->GetOutput);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($laplacian->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(0);
#viewer DebugOn
do 'WindowLevelInterface.pl';
