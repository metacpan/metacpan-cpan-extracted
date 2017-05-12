#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test the threshold filter.
# Values above 2000 are set to 255.
# Values below 2000 are set to 0.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$cast = Graphics::VTK::ImageCast->new;
$cast->SetOutputScalarType($VTK_SHORT);
$cast->SetInput($reader->GetOutput);
$thresh = Graphics::VTK::ImageThreshold->new;
$thresh->SetInput($cast->GetOutput);
$thresh->ThresholdByUpper(2000.0);
$thresh->SetInValue(0);
$thresh->SetOutValue(200);
$thresh->ReleaseDataFlagOff;
$dist = Graphics::VTK::ImageCityBlockDistance->new;
$dist->SetDimensionality(2);
$dist->SetInput($thresh->GetOutput);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($dist->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(117);
$viewer->SetColorLevel(43);
# make interface
do 'WindowLevelInterface.pl';
