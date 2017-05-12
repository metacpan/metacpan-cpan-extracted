#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This scripts shows a compressed spectrum of an image.
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
$magnitude = Graphics::VTK::ImageMagnitude->new;
$magnitude->SetInput($fft->GetOutput);
$magnitude->ReleaseDataFlagOff;
$center = Graphics::VTK::ImageFourierCenter->new;
$center->SetInput($magnitude->GetOutput);
$center->SetFilteredAxes($VTK_IMAGE_X_AXIS,$VTK_IMAGE_Y_AXIS);
$compress = Graphics::VTK::ImageLogarithmicScale->new;
$compress->SetInput($center->GetOutput);
$compress->SetConstant(15);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($compress->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(150);
$viewer->SetColorLevel(170);
do 'WindowLevelInterface.pl';
