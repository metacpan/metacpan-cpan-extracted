#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script shows the result of an ideal highpass filter in frequency space.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$fft = Graphics::VTK::ImageFFT->new;
$fft->SetDimensionality(2);
$fft->SetInput($reader->GetOutput);
#fft DebugOn
$highPass = Graphics::VTK::ImageButterworthHighPass->new;
$highPass->SetInput($fft->GetOutput);
$highPass->SetOrder(2);
$highPass->SetXCutOff(0.2);
$highPass->SetYCutOff(0.1);
$highPass->ReleaseDataFlagOff;
#highPass DebugOn
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($highPass->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(10000);
$viewer->SetColorLevel(5000);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
