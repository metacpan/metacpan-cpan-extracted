#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This scripts the reverse FFT. Pipeline is Reader->FFT->RFFT->Viewer.
# Output should be the same as Reader.
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
$rfft = Graphics::VTK::ImageRFFT->new;
$rfft->SetDimensionality(2);
$rfft->SetInput($fft->GetOutput);
$rfft->ReleaseDataFlagOff;
#fft DebugOn
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($rfft->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
