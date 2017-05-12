#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$imageFloat = Graphics::VTK::ImageCast->new;
$imageFloat->SetInput($reader->GetOutput);
$imageFloat->SetOutputScalarTypeToFloat;
$flipX = Graphics::VTK::ImageFlip->new;
$flipX->SetInput($imageFloat->GetOutput);
$flipX->SetFilteredAxes($VTK_IMAGE_X_AXIS);
$flipY = Graphics::VTK::ImageFlip->new;
$flipY->SetInput($imageFloat->GetOutput);
$flipY->SetFilteredAxes($VTK_IMAGE_Y_AXIS);
$append = Graphics::VTK::ImageAppend->new;
$AddInput = $AddInput . $imageFloat->GetOutput;
$AddInput = $AddInput . $flipX->GetOutput;
$AddInput = $AddInput . $flipY->GetOutput;
$SetAppendAxis = $SetAppendAxis . $VTK_IMAGE_X_AXIS;
#flip BypassOn
#flip PreserveImageExtentOn
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($append->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
#make interface
do 'WindowLevelInterface.pl';
