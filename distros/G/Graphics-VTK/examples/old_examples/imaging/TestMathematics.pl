#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test the Arithmetic filter.
# An image is smoothed then sbutracted from the original image.
# The result is a high-pass filter.
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
$shiftScale = Graphics::VTK::ImageShiftScale->new;
$shiftScale->SetInput($cast->GetOutput);
$shiftScale->SetShift(1.0);
$log = Graphics::VTK::ImageMathematics->new;
$log->SetOperationToLog;
$log->SetInput1($shiftScale->GetOutput);
$log->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($log->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(4);
$viewer->SetColorLevel(6);
$viewer->Render;
# make interface
do 'WindowLevelInterface.pl';
