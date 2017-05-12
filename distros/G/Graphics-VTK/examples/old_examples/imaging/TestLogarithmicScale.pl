#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This scripts Compresses the complex components of an image in frequency
# space to view more detail.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->GetOutput->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$fft = Graphics::VTK::ImageFFT->new;
$fft->SetFilteredAxes($VTK_IMAGE_X_AXIS,$VTK_IMAGE_Y_AXIS);
$fft->SetInput($reader->GetOutput);
$fft->ReleaseDataFlagOff;
#fft DebugOn
$compress = Graphics::VTK::ImageLogarithmicScale->new;
$compress->SetInput($fft->GetOutput);
$compress->SetConstant(15);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($compress->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(500);
$viewer->SetColorLevel(0);
do 'WindowLevelInterface.pl';
