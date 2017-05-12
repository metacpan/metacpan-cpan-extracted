#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script shows the result of an ideal highpass filter in  spatial domain
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
$highPass = Graphics::VTK::ImageIdealHighPass->new;
$highPass->SetInput($fft->GetOutput);
$highPass->SetXCutOff(0.1);
$highPass->SetYCutOff(0.1);
$highPass->ReleaseDataFlagOff;
#highPass DebugOn
$rfft = Graphics::VTK::ImageRFFT->new;
$rfft->SetFilteredAxes($VTK_IMAGE_X_AXIS,$VTK_IMAGE_Y_AXIS);
$rfft->SetInput($highPass->GetOutput);
#fft DebugOn
$real = Graphics::VTK::ImageExtractComponents->new;
$real->SetInput($rfft->GetOutput);
$real->SetComponents(0);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($real->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(500);
$viewer->SetColorLevel(0);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
