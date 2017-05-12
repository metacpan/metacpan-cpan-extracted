#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test the mask filter.
# removes all but a sphere of headSq.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,94);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$sphere = Graphics::VTK::ImageEllipsoidSource->new;
$sphere->SetWholeExtent(0,255,0,255,1,94);
$sphere->SetCenter(128,128,46);
$sphere->SetRadius(80,80,80);
$mask = Graphics::VTK::ImageMask->new;
$mask->SetImageInput($reader->GetOutput);
$mask->SetMaskInput($sphere->GetOutput);
$mask->SetMaskedOutputValue(500);
$mask->NotMaskOn;
$mask->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($mask->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
