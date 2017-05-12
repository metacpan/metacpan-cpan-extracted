#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script subtracts the 2D laplacian from an image to enhance the edges.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
#reader DebugOn
$reader->GetOutput->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$cast = Graphics::VTK::ImageCast->new;
$cast->SetInput($reader->GetOutput);
$cast->SetOutputScalarTypeToFloat;
$lap = Graphics::VTK::ImageLaplacian->new;
$lap->SetInput($cast->GetOutput);
$lap->SetDimensionality(2);
$subtract = Graphics::VTK::ImageMathematics->new;
$subtract->SetOperationToSubtract;
$subtract->SetInput1($cast->GetOutput);
$subtract->SetInput2($lap->GetOutput);
$subtract->ReleaseDataFlagOff;
#subtract BypassOn
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($subtract->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
# make interface
do 'WindowLevelInterface.pl';
