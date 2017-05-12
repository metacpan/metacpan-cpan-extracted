#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script shows the result of an ideal lowpass filter in frequency space.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$fft = Graphics::VTK::ImageFFT->new;
$fft->SetFilteredAxes($VTK_IMAGE_X_AXIS,$VTK_IMAGE_Y_AXIS);
$fft->SetInput($reader->GetOutput);
#fft DebugOn
$lowPass = Graphics::VTK::ImageIdealLowPass->new;
$lowPass->SetInput($fft->GetOutput);
$lowPass->SetXCutOff(0.2);
$lowPass->SetYCutOff(0.1);
$lowPass->ReleaseDataFlagOff;
#lowPass DebugOn
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($lowPass->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(10000);
$viewer->SetColorLevel(5000);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
