#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This scripts shows the real component of an image in frequencey space.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->GetOutput->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$fft = Graphics::VTK::ImageFFT->new;
$fft->SetDimensionality(2);
$fft->SetInput($reader->GetOutput);
$fft->ReleaseDataFlagOff;
#fft DebugOn
$center = Graphics::VTK::ImageFourierCenter->new;
$center->SetInput($fft->GetOutput);
$center->SetDimensionality(2);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($center->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(10000);
$viewer->SetColorLevel(4000);
do 'WindowLevelInterface.pl';
