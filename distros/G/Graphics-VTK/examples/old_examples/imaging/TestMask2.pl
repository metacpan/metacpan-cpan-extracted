#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test the mask filter.
#  replaces a circle with a color
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::PNMReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetFileName("$VTK_DATA/earth.ppm");
$sphere = Graphics::VTK::ImageEllipsoidSource->new;
$sphere->SetWholeExtent(0,511,0,255,0,0);
$sphere->SetCenter(128,128,0);
$sphere->SetRadius(80,80,1);
$mask = Graphics::VTK::ImageMask->new;
$mask->SetImageInput($reader->GetOutput);
$mask->SetMaskInput($sphere->GetOutput);
$mask->SetMaskedOutputValue(100,128,200);
$mask->NotMaskOn;
$mask->ReleaseDataFlagOff;
$sphere2 = Graphics::VTK::ImageEllipsoidSource->new;
$sphere2->SetWholeExtent(0,511,0,255,0,0);
$sphere2->SetCenter(328,128,0);
$sphere2->SetRadius(80,50,1);
# Test the wrapping of the output masked value
$mask2 = Graphics::VTK::ImageMask->new;
$mask2->SetImageInput($mask->GetOutput);
$mask2->SetMaskInput($sphere2->GetOutput);
$mask2->SetMaskedOutputValue(100);
$mask2->NotMaskOn;
$mask2->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($mask2->GetOutput);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(128);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
